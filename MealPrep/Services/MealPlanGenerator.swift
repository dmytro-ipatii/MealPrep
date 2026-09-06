//
//  MealPlanGenerator.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Orchestrates Pass A: generate a week's skeleton, validate it, and repair it
/// until it is shippable — or fail. A plan that is over budget or violates a
/// dietary need must never reach the user.
///
/// Repair order matters. The deterministic strategies are instant and free, so
/// they run before the first repair prompt and again after every LLM round.
/// LLM repair is capped at two attempts, after which deterministic downgrading
/// gets the last word.
actor MealPlanGenerator {

    static let daysPerPlan = 7
    static let maximumLLMRepairAttempts = 2

    private let client: MealPlanLLMClient

    init(client: MealPlanLLMClient) {
        self.client = client
    }

    /// The whole of Pass A and Pass B: a validated skeleton, then recipe prose
    /// for all seven days concurrently.
    func generatePlan(
        configuration: MealPlanConfiguration,
        candidates: [Product],
        generatedAt: Date = Date()
    ) async throws -> MealPlan {
        let skeleton = try await generateSkeleton(
            configuration: configuration,
            candidates: candidates
        )

        let recipesByDay = try await generateRecipes(
            for: skeleton,
            configuration: configuration,
            candidates: candidates
        )

        return try MealPlanAssembler.assemble(
            skeleton: skeleton,
            recipesByDay: recipesByDay,
            candidates: candidates,
            configuration: configuration,
            generatedAt: generatedAt
        )
    }

    /// Seven independent calls, one per day, run concurrently — sequentially
    /// this is the slowest part of generation by a wide margin. Cancelling the
    /// enclosing task cancels the in-flight requests.
    private func generateRecipes(
        for skeleton: PlanSkeleton,
        configuration: MealPlanConfiguration,
        candidates: [Product]
    ) async throws -> [Int: DayRecipes] {
        let productsByID = Dictionary(
            candidates.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

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
            }
            return results
        }
    }

    func generateSkeleton(
        configuration: MealPlanConfiguration,
        candidates: [Product]
    ) async throws -> PlanSkeleton {
        let skuLimit = PlanSkeletonPromptBuilder.skuBudget(for: Self.daysPerPlan)

        var skeleton = try await client.generatePlanSkeleton(
            PlanSkeletonRequest(
                dayCount: Self.daysPerPlan,
                configuration: configuration,
                candidates: candidates
            )
        )

        skeleton = PlanRepairService.repair(
            skeleton,
            candidates: candidates,
            configuration: configuration,
            skuLimit: skuLimit
        )

        var violations = validate(skeleton, candidates: candidates, configuration: configuration, skuLimit: skuLimit)

        var attempt = 0
        while violations.contains(where: \.isBlocking), attempt < Self.maximumLLMRepairAttempts {
            attempt += 1

            let repaired = try await client.repairPlanSkeleton(
                PlanRepairRequest(
                    skeleton: skeleton,
                    violations: violations,
                    configuration: configuration,
                    candidates: candidates,
                    skuLimit: skuLimit
                )
            )

            skeleton = PlanRepairService.repair(
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
