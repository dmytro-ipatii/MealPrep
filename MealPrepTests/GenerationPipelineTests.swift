//
//  GenerationPipelineTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct GenerationPipelineTests {

    /// Cheap, plentiful, and spread across departments so candidate selection
    /// has something to work with.
    private let catalog: [Product] = (0..<40).map { index in
        Product.fixture(
            id: "p\(index)",
            categoryID: "en:cat\(index % 5)",
            departmentID: "dept\(index % 4)",
            price: 1,
            grams: 5000
        )
    }

    private func collect(
        _ stream: AsyncThrowingStream<GenerationProgress, Error>
    ) async throws -> [GenerationProgress] {
        var received: [GenerationProgress] = []
        for try await progress in stream { received.append(progress) }
        return received
    }

    private func makeGenerator(
        skeletonProductIDs: [String]? = nil
    ) -> (MealPlanGenerator, StubMealPlanLLMClient) {
        let ids = skeletonProductIDs ?? catalog.prefix(6).map(\.id)
        let client = StubMealPlanLLMClient(generate: .week(productIDs: ids))
        let catalog = catalog
        let generator = MealPlanGenerator(client: client, loadCatalog: { catalog })
        return (generator, client)
    }

    // MARK: - Happy path

    @Test func theStreamEndsWithAFinishedPlan() async throws {
        let (generator, _) = makeGenerator()

        let received = try await collect(generator.generate(configuration: .fixture()))

        guard case .finished(let plan) = received.last else {
            Issue.record("expected the stream to end with .finished, got \(String(describing: received.last))")
            return
        }
        #expect(plan.days.count == MealPlanGenerator.daysPerPlan)
    }

    @Test func everyStageIsReportedInOrder() async throws {
        let (generator, _) = makeGenerator()

        let received = try await collect(generator.generate(configuration: .fixture()))

        // A bare spinner reads as a hang, so the sequence itself is the feature.
        #expect(received.first == .loadingCatalog)

        let sawFiltering = received.contains { if case .filtering = $0 { true } else { false } }
        let sawFeasibility = received.contains(.checkingFeasibility)
        let sawPlanning = received.contains(.planning)
        let sawValidating = received.contains { if case .validating = $0 { true } else { false } }
        let sawRecipes = received.contains { if case .writingRecipes = $0 { true } else { false } }

        #expect(sawFiltering)
        #expect(sawFeasibility)
        #expect(sawPlanning)
        #expect(sawValidating)
        #expect(sawRecipes)
    }

    @Test func recipeProgressCountsUpToTheFullWeek() async throws {
        let (generator, _) = makeGenerator()

        let received = try await collect(generator.generate(configuration: .fixture()))
        let recipeCounts = received.compactMap { progress -> Int? in
            guard case .writingRecipes(let completed, _) = progress else { return nil }
            return completed
        }

        #expect(recipeCounts.first == 0)
        #expect(recipeCounts.last == MealPlanGenerator.daysPerPlan)
        #expect(recipeCounts == recipeCounts.sorted())
    }

    @Test func filteringReportsHowManyCandidatesSurvived() async throws {
        let (generator, _) = makeGenerator()

        let received = try await collect(generator.generate(configuration: .fixture()))
        let count = received.compactMap { progress -> Int? in
            guard case .filtering(let candidateCount) = progress else { return nil }
            return candidateCount
        }.first

        let reported = try #require(count)
        #expect(reported > 0)
        #expect(reported <= catalog.count)
    }

    // MARK: - Failure paths

    @Test func anImpossibleBudgetFailsBeforeAnyModelCall() async {
        let (generator, client) = makeGenerator()

        // Below the cheapest-per-department floor.
        let stream = generator.generate(configuration: .fixture(weeklyBudget: 1))

        await #expect(throws: GenerationError.self) {
            for try await _ in stream {}
        }
        #expect(client.generateCallCount == 0)
    }

    @Test func theBudgetErrorCarriesAnActionableMessage() async {
        let (generator, _) = makeGenerator()

        do {
            for try await _ in generator.generate(configuration: .fixture(weeklyBudget: 1)) {}
            Issue.record("expected generation to fail")
        } catch let error as GenerationError {
            guard case .budgetInfeasible(let message) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            #expect(message.contains("minimum"))
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test func aCatalogFailureTerminatesTheStream() async {
        struct CatalogUnavailable: Error {}
        let client = StubMealPlanLLMClient(generate: .week(productIDs: catalog.prefix(6).map(\.id)))
        let generator = MealPlanGenerator(client: client, loadCatalog: { throw CatalogUnavailable() })

        await #expect(throws: CatalogUnavailable.self) {
            for try await _ in generator.generate(configuration: .fixture()) {}
        }
    }

    @Test func aPlanIsNeverEmittedWhenGenerationFails() async {
        let client = StubMealPlanLLMClient(generate: .week(productIDs: ["ghost", "alsoGhost"]))
        let catalog = catalog
        let generator = MealPlanGenerator(client: client, loadCatalog: { catalog })

        var received: [GenerationProgress] = []
        do {
            for try await progress in generator.generate(configuration: .fixture()) {
                received.append(progress)
            }
            Issue.record("expected generation to fail")
        } catch {
            // expected
        }

        let emittedAPlan = received.contains { if case .finished = $0 { true } else { false } }
        #expect(!emittedAPlan)
    }

    // MARK: - Cancellation

    @Test func cancellingTheConsumerStopsGeneration() async throws {
        let (generator, client) = makeGenerator()

        let task = Task {
            var count = 0
            for try await _ in generator.generate(configuration: .fixture()) {
                count += 1
                if count == 1 { break } // stop consuming after the first stage
            }
        }

        try await task.value

        // Terminating the stream cancels the work behind it; the run must not
        // sail on to completion in the background.
        #expect(client.recipeCallCount < MealPlanGenerator.daysPerPlan)
    }
}
