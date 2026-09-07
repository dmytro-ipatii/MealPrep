//
//  MealPlanRepositoryTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import MealPrep

@MainActor
struct MealPlanRepositoryTests {

    private let products = (0..<6).map { Product.fixture(id: "p\($0)", price: 2, grams: 1000) }

    /// A real container, just held in memory — mapping bugs (unordered
    /// relationships, lossy enums) only show up against actual SwiftData.
    private func makeRepository() throws -> SwiftDataMealPlanRepository {
        let container = try ModelContainer(
            for: StoredConfiguration.self, StoredMealPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return SwiftDataMealPlanRepository(modelContext: ModelContext(container))
    }

    private func samplePlan(
        configuration: MealPlanConfiguration = .fixture(dietaryNeeds: [.vegan], goals: [.highProtein])
    ) throws -> MealPlan {
        let skeleton = PlanSkeleton.week(productIDs: products.map(\.id))
        return try MealPlanAssembler.assemble(
            skeleton: skeleton,
            recipesByDay: Dictionary(
                uniqueKeysWithValues: skeleton.days.map { ($0.dayIndex, DayRecipes.covering($0)) }
            ),
            candidates: products,
            configuration: configuration,
            generatedAt: Date(timeIntervalSince1970: 1_000_000)
        )
    }

    // MARK: - Round trip

    @Test func noPlanIsStoredInitially() throws {
        let repository = try makeRepository()
        #expect(repository.loadLatestPlan() == nil)
    }

    @Test func aSavedPlanReloadsIdentically() throws {
        let repository = try makeRepository()
        let plan = try samplePlan()

        try repository.save(plan)
        let reloaded = try #require(repository.loadLatestPlan())

        #expect(reloaded == plan)
    }

    @Test func daysAndMealsComeBackInOrder() throws {
        let repository = try makeRepository()
        try repository.save(try samplePlan())

        let reloaded = try #require(repository.loadLatestPlan())

        #expect(reloaded.days.map(\.dayIndex) == Array(0..<7))
        for day in reloaded.days {
            #expect(day.meals.map(\.slot) == [.breakfast, .lunch, .dinner])
        }
    }

    @Test func recipesSurviveTheRoundTrip() throws {
        let repository = try makeRepository()
        try repository.save(try samplePlan())

        let reloaded = try #require(repository.loadLatestPlan())
        let meal = try #require(reloaded.days.first?.meals.first)

        #expect(!meal.recipe.steps.isEmpty)
        #expect(!meal.recipe.ingredientLines.isEmpty)
    }

    @Test func theShoppingListAndItsCostsSurvive() throws {
        let repository = try makeRepository()
        let plan = try samplePlan()

        try repository.save(plan)
        let reloaded = try #require(repository.loadLatestPlan())

        #expect(reloaded.shoppingList.count == plan.shoppingList.count)
        #expect(reloaded.totalCost == plan.totalCost)
        #expect(reloaded.totalWasteQuantity == plan.totalWasteQuantity)
    }

    @Test func theConfigurationTheePlanWasBuiltForSurvives() throws {
        let repository = try makeRepository()
        let configuration = MealPlanConfiguration.fixture(
            weeklyBudget: 55,
            dietaryNeeds: [.vegan, .glutenFree],
            goals: [.lowSugar]
        )

        try repository.save(try samplePlan(configuration: configuration))
        let reloaded = try #require(repository.loadLatestPlan())

        #expect(reloaded.configuration.weeklyBudget == 55)
        #expect(reloaded.configuration.dietaryNeeds == [.vegan, .glutenFree])
        #expect(reloaded.configuration.goals == [.lowSugar])
    }

    @Test func pantryStaplesSurviveAsTypedValues() throws {
        let repository = try makeRepository()
        try repository.save(try samplePlan())

        let reloaded = try #require(repository.loadLatestPlan())
        let meal = try #require(reloaded.days.first?.meals.first)

        #expect(meal.pantryItems == [.salt])
    }

    // MARK: - Replacement and deletion

    @Test func savingAgainReplacesThePreviousPlanRatherThanAccumulating() throws {
        let repository = try makeRepository()

        try repository.save(try samplePlan(configuration: .fixture(weeklyBudget: 30)))
        try repository.save(try samplePlan(configuration: .fixture(weeklyBudget: 90)))

        let reloaded = try #require(repository.loadLatestPlan())
        #expect(reloaded.configuration.weeklyBudget == 90)
    }

    @Test func deleteAllRemovesTheStoredPlan() throws {
        let repository = try makeRepository()
        try repository.save(try samplePlan())

        try repository.deleteAll()

        #expect(repository.loadLatestPlan() == nil)
    }

    // MARK: - Independence from the catalog

    @Test func aReloadedPlanRendersWithoutTheCatalog() throws {
        // Nothing in the reload path resolves against product_catalog_en.json,
        // so a plan still renders after the bundled catalog changes.
        let repository = try makeRepository()
        try repository.save(try samplePlan())

        let reloaded = try #require(repository.loadLatestPlan())
        let ingredients = reloaded.days.flatMap { $0.meals.flatMap(\.ingredients) }

        #expect(!ingredients.isEmpty)
        #expect(ingredients.allSatisfy { !$0.productName.isEmpty })
        #expect(reloaded.shoppingList.allSatisfy { !$0.productName.isEmpty })
    }
}
