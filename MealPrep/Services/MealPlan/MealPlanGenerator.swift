//
//  MealPlanGenerator.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Orchestrates the whole pipeline: catalog, filtering, ranking, selection,
/// feasibility, Pass A with repair, then Pass B recipes.
///
/// A plan that is over budget or violates a dietary need must never reach the
/// user, so generation fails rather than degrades. Repair order matters: the
/// deterministic strategies are instant and free, so they run before the first
/// repair prompt and again after every LLM round. LLM repair is capped at two
/// attempts, after which deterministic downgrading gets the last word.
actor MealPlanGenerator {

    static let daysPerPlan = 7
    static let maximumLLMRepairAttempts = 2

    typealias ProgressHandler = @Sendable (GenerationProgress) -> Void

    private let client: MealPlanLLMClient
    private let loadCatalog: @Sendable () throws -> [Product]

    init(
        client: MealPlanLLMClient,
        loadCatalog: @escaping @Sendable () throws -> [Product] = {
            try ProductCatalogLoader.load().products
        }
    ) {
        self.client = client
        self.loadCatalog = loadCatalog
    }

    // MARK: - Full pipeline

    /// Runs the pipeline, reporting each stage as it goes. The stream ends
    /// with `.finished(plan)`, or terminates with the error that stopped it.
    /// Cancelling the consuming task cancels the in-flight requests.
    nonisolated func generate(
        configuration: MealPlanConfiguration
    ) -> AsyncThrowingStream<GenerationProgress, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let plan = try await self.runPipeline(configuration: configuration) { progress in
                        continuation.yield(progress)
                    }
                    continuation.yield(.finished(plan))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func runPipeline(
        configuration: MealPlanConfiguration,
        onProgress: @escaping ProgressHandler
    ) async throws -> MealPlan {
        onProgress(.loadingCatalog)
        let products = try loadCatalog()

        let safeProducts = await DietaryFilterService.filter(products, for: configuration.dietaryNeeds)
        let scores = await GoalRankingService.score(safeProducts, for: configuration.goals)
        let candidates = await CandidateSelector.select(from: safeProducts, scores: scores)
        onProgress(.filtering(candidateCount: candidates.count))

        try Task.checkCancellation()

        onProgress(.checkingFeasibility)
        if case .infeasible(_, let message) = await FeasibilityChecker.checkFeasibility(
            candidates: candidates,
            configuration: configuration
        ) {
            throw GenerationError.budgetInfeasible(message: message)
        }

        return try await generatePlan(
            configuration: configuration,
            candidates: candidates,
            onProgress: onProgress
        )
    }

    // MARK: - Pass A and Pass B

    /// The AI half of the pipeline, separated so it can be driven directly
    /// with a fixed candidate list.
    func generatePlan(
        configuration: MealPlanConfiguration,
        candidates: [Product],
        generatedAt: Date = Date(),
        onProgress: ProgressHandler? = nil
    ) async throws -> MealPlan {
        let skeleton = try await generateSkeleton(
            configuration: configuration,
            candidates: candidates,
            onProgress: onProgress
        )

        let recipesByDay = try await generateRecipes(
            for: skeleton,
            configuration: configuration,
            candidates: candidates,
            onProgress: onProgress
        )

        return try await MealPlanAssembler.assemble(
            skeleton: skeleton,
            recipesByDay: recipesByDay,
            candidates: candidates,
            configuration: configuration,
            generatedAt: generatedAt
        )
    }

    func generateSkeleton(
        configuration: MealPlanConfiguration,
        candidates: [Product],
        onProgress: ProgressHandler? = nil
    ) async throws -> PlanSkeleton {
        let skuLimit = await PlanSkeletonPromptBuilder.skuBudget(for: Self.daysPerPlan)

        onProgress?(.planning)
        var skeleton = try await client.generatePlanSkeleton(
            PlanSkeletonRequest(
                dayCount: Self.daysPerPlan,
                configuration: configuration,
                candidates: candidates
            )
        )

        skeleton = await PlanRepairService.repair(
            skeleton,
            candidates: candidates,
            configuration: configuration,
            skuLimit: skuLimit
        )

        onProgress?(.validating(attempt: 1))
        var violations = validate(skeleton, candidates: candidates, configuration: configuration, skuLimit: skuLimit)

        var attempt = 0
        while violations.contains(where: \.isBlocking), attempt < Self.maximumLLMRepairAttempts {
            attempt += 1
            try Task.checkCancellation()
            onProgress?(.validating(attempt: attempt + 1))

            let repaired = try await client.repairPlanSkeleton(
                PlanRepairRequest(
                    skeleton: skeleton,
                    violations: violations,
                    configuration: configuration,
                    candidates: candidates,
                    skuLimit: skuLimit
                )
            )

            skeleton = await PlanRepairService.repair(
                repaired,
                candidates: candidates,
                configuration: configuration,
                skuLimit: skuLimit
            )

            violations = validate(skeleton, candidates: candidates, configuration: configuration, skuLimit: skuLimit)
        }

        let blocking = violations.filter(\.isBlocking)
        guard blocking.isEmpty else {
            throw GenerationError.couldNotSatisfyConstraints(violations: blocking)
        }

        return skeleton
    }

    /// Seven independent calls, one per day, run concurrently — sequentially
    /// this is the slowest part of generation by a wide margin.
    private func generateRecipes(
        for skeleton: PlanSkeleton,
        configuration: MealPlanConfiguration,
        candidates: [Product],
        onProgress: ProgressHandler?
    ) async throws -> [Int: DayRecipes] {
        let productsByID = Dictionary(
            candidates.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let total = skeleton.days.count
        onProgress?(.writingRecipes(completed: 0, total: total))

        return try await withThrowingTaskGroup(of: (Int, DayRecipes).self) { group in
            for day in skeleton.days {
                let usedProducts = Set(day.meals.flatMap { $0.ingredients.map(\.productID) })
                    .compactMap { productsByID[$0] }
                    .sorted { $0.id < $1.id }

                group.addTask { [client] in
                    let recipes = try await client.generateRecipes(
                        RecipeRequest(
                            day: day,
                            products: usedProducts,
                            configuration: configuration
                        )
                    )
                    return (day.dayIndex, recipes)
                }
            }

            var results: [Int: DayRecipes] = [:]
            for try await (dayIndex, recipes) in group {
                results[dayIndex] = recipes
                onProgress?(.writingRecipes(completed: results.count, total: total))
            }
            return results
        }
    }

    private func validate(
        _ skeleton: PlanSkeleton,
        candidates: [Product],
        configuration: MealPlanConfiguration,
        skuLimit: Int
    ) -> [PlanViolation] {
        PlanValidator.validate(
            skeleton,
            candidates: candidates,
            configuration: configuration,
            expectedDayCount: Self.daysPerPlan,
            skuLimit: skuLimit
        )
    }
}
