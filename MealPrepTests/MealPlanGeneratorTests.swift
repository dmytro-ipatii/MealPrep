//
//  MealPlanGeneratorTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct MealPlanGeneratorTests {

    private let cheapProducts = (0..<6).map { Product.fixture(id: "p\($0)", categoryID: "en:pastas") }

    /// One product per meal at a price no budget survives — the case the
    /// repair loop exists for.
    private let expensiveProducts = (0..<21).map {
        Product.fixture(id: "x\($0)", categoryID: "en:pastas", price: 6, grams: 5000)
    }

    @Test func returnsThePlanUntouchedWhenPassAIsAlreadyValid() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)

        let result = try await generator.generateSkeleton(
            configuration: .fixture(),
            candidates: cheapProducts
        )

        #expect(result == valid)
        #expect(client.repairCallCount == 0)
    }

    @Test func deterministicRepairRunsBeforeAnyLLMRepairCall() async throws {
        // A single pricey one-off product blows the budget. Consolidating it
        // onto a product already in the basket fixes that offline, so no
        // repair prompt should ever be sent.
        let luxury = Product.fixture(id: "luxury", categoryID: "en:pastas", price: 30, grams: 5000)
        let candidates = cheapProducts + [luxury]
        let overBudget = PlanSkeleton
            .week(productIDs: cheapProducts.map(\.id))
            .replacingFirstIngredient(with: "luxury")

        let client = StubMealPlanLLMClient(generate: overBudget)
        let generator = MealPlanGenerator(client: client)

        let result = try await generator.generateSkeleton(
            configuration: .fixture(weeklyBudget: 10),
            candidates: candidates
        )

        #expect(client.repairCallCount == 0)
        #expect(!result.distinctProductIDs.contains("luxury"))

        let basket = CostCalculator.basket(
            for: PlanValidator.usages(in: result, productsByID: lookup(candidates))
        )
        #expect(basket.totalCost <= 10)
    }

    @Test func fallsBackToLLMRepairWhenNoDeterministicMoveExists() async throws {
        // 21 products, each used exactly twice, all the same price: nothing to
        // consolidate, nothing cheaper to substitute, no package boundary to
        // cross, and every meal is already at the two-ingredient minimum.
        let stuck = PlanSkeleton.week(productIDs: expensiveProducts.map(\.id))
        // The model's fix: carry the week on three products instead of 21.
        let fixed = PlanSkeleton.week(productIDs: expensiveProducts.prefix(3).map(\.id))
        let client = StubMealPlanLLMClient(generate: stuck, repairs: [fixed])
        let generator = MealPlanGenerator(client: client)

        let result = try await generator.generateSkeleton(
            configuration: .fixture(weeklyBudget: 20),
            candidates: expensiveProducts
        )

        #expect(client.repairCallCount == 1)
        #expect(result == fixed)
    }

    @Test func callsLLMRepairWhenDeterministicRepairCannotFixTheProblem() async throws {
        // A hallucinated product is not something consolidation can repair —
        // only the model can replace it.
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let fixed = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: broken, repairs: [fixed])
        let generator = MealPlanGenerator(client: client)

        let result = try await generator.generateSkeleton(
            configuration: .fixture(),
            candidates: cheapProducts
        )

        #expect(client.repairCallCount == 1)
        #expect(result == fixed)
    }

    @Test func theRepairRequestCarriesTheViolationsThatCausedIt() async throws {
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let fixed = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: broken, repairs: [fixed])
        let generator = MealPlanGenerator(client: client)

        _ = try await generator.generateSkeleton(configuration: .fixture(), candidates: cheapProducts)

        let request = try #require(client.repairRequests.first)
        let mentionsGhost = request.violations.contains {
            $0 == .unknownProduct(id: "ghost", day: 0, slot: .breakfast)
        }
        #expect(mentionsGhost)
        #expect(request.skeleton == broken)
    }

    @Test func llmRepairIsCappedAtTwoAttempts() async {
        // The model keeps returning the same broken plan.
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let client = StubMealPlanLLMClient(generate: broken, repairs: [broken, broken, broken])
        let generator = MealPlanGenerator(client: client)

        _ = try? await generator.generateSkeleton(configuration: .fixture(), candidates: cheapProducts)

        #expect(client.repairCallCount == MealPlanGenerator.maximumLLMRepairAttempts)
    }

    @Test func throwsRatherThanShowingAPlanThatStillViolatesConstraints() async {
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let client = StubMealPlanLLMClient(generate: broken, repairs: [broken])
        let generator = MealPlanGenerator(client: client)

        await #expect(throws: GenerationError.self) {
            try await generator.generateSkeleton(configuration: .fixture(), candidates: cheapProducts)
        }
    }

    @Test func theThrownErrorCarriesOnlyBlockingViolations() async {
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let client = StubMealPlanLLMClient(generate: broken, repairs: [broken])
        let generator = MealPlanGenerator(client: client)

        // A goal that cannot be met, on top of the blocking problem.
        let configuration = MealPlanConfiguration.fixture(goals: [.highProtein])

        do {
            _ = try await generator.generateSkeleton(configuration: configuration, candidates: cheapProducts)
            Issue.record("expected the generator to throw")
        } catch let error as GenerationError {
            guard case .couldNotSatisfyConstraints(let violations) = error else {
                Issue.record("unexpected error: \(error)")
                return
            }
            let allBlocking = violations.allSatisfy(\.isBlocking)
            #expect(allBlocking)
            #expect(!violations.isEmpty)
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }

    @Test func aMissedNutritionalGoalAloneNeverBlocksThePlan() async throws {
        // Every product is protein-poor, so the high-protein goal cannot be
        // met — but a soft preference must not cost the user their whole plan.
        let leanProducts = (0..<6).map {
            Product.fixture(id: "lean\($0)", categoryID: "en:vegetables", proteins: 0.2)
        }
        let plan = PlanSkeleton.week(productIDs: leanProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: plan)
        let generator = MealPlanGenerator(client: client)

        let result = try await generator.generateSkeleton(
            configuration: .fixture(goals: [.highProtein]),
            candidates: leanProducts
        )

        #expect(result == plan)
        #expect(client.repairCallCount == 0)
    }

    @Test func propagatesAFailureFromPassA() async {
        struct Boom: Error {}
        let client = StubMealPlanLLMClient(generate: .week(productIDs: cheapProducts.map(\.id)))
        client.generateResult = .failure(Boom())
        let generator = MealPlanGenerator(client: client)

        await #expect(throws: Boom.self) {
            try await generator.generateSkeleton(configuration: .fixture(), candidates: cheapProducts)
        }
    }

    // MARK: - Pass B

    @Test func generatesRecipesForEveryDayOfTheWeek() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)

        let plan = try await generator.generatePlan(
            configuration: .fixture(),
            candidates: cheapProducts
        )

        #expect(client.recipeCallCount == MealPlanGenerator.daysPerPlan)
        #expect(plan.days.count == MealPlanGenerator.daysPerPlan)

        let everyMealHasARecipe = plan.days.flatMap(\.meals).allSatisfy { !$0.recipe.isEmpty }
        #expect(everyMealHasARecipe)
    }

    @Test func theSevenRecipeCallsRunConcurrentlyNotOneAfterAnother() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)

        _ = try await generator.generatePlan(configuration: .fixture(), candidates: cheapProducts)

        // Sequential execution would never show more than one in flight.
        #expect(client.peakConcurrentRecipeCalls > 1)
    }

    @Test func eachRecipeRequestOnlyCarriesThatDaysProducts() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)

        _ = try await generator.generatePlan(configuration: .fixture(), candidates: cheapProducts)

        for request in client.recipeRequests {
            let dayProductIDs = Set(request.day.meals.flatMap { $0.ingredients.map(\.productID) })
            #expect(Set(request.products.map(\.id)) == dayProductIDs)
        }
    }

    @Test func requestsCoverEveryDayIndexExactlyOnce() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)

        _ = try await generator.generatePlan(configuration: .fixture(), candidates: cheapProducts)

        let requestedDays = client.recipeRequests.map(\.day.dayIndex).sorted()
        #expect(requestedDays == Array(0..<MealPlanGenerator.daysPerPlan))
    }

    @Test func aFailureInOneRecipeCallFailsTheWholeGeneration() async {
        struct RecipeBoom: Error {}
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        client.recipeProvider = { request in
            // Persisting a half-written plan is worse than failing outright.
            if request.day.dayIndex == 4 { throw RecipeBoom() }
            return .covering(request.day)
        }
        let generator = MealPlanGenerator(client: client)

        await #expect(throws: RecipeBoom.self) {
            try await generator.generatePlan(configuration: .fixture(), candidates: cheapProducts)
        }
    }

    @Test func passBNeverRunsWhenPassAFailsValidation() async {
        let broken = PlanSkeleton.week(productIDs: ["ghost", "p1"])
        let client = StubMealPlanLLMClient(generate: broken, repairs: [broken])
        let generator = MealPlanGenerator(client: client)

        _ = try? await generator.generatePlan(configuration: .fixture(), candidates: cheapProducts)

        // No point writing prose for a plan that will never ship.
        #expect(client.recipeCallCount == 0)
    }

    @Test func theFinishedPlanIsPricedWithinBudget() async throws {
        let valid = PlanSkeleton.week(productIDs: cheapProducts.map(\.id))
        let client = StubMealPlanLLMClient(generate: valid)
        let generator = MealPlanGenerator(client: client)
        let configuration = MealPlanConfiguration.fixture(weeklyBudget: 70)

        let plan = try await generator.generatePlan(
            configuration: configuration,
            candidates: cheapProducts
        )

        #expect(plan.totalCost <= configuration.weeklyBudget)
        #expect(plan.totalCost > 0)
        #expect(plan.skuCount == cheapProducts.count)
    }

    private func lookup(_ products: [Product]) -> [String: Product] {
        Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}
