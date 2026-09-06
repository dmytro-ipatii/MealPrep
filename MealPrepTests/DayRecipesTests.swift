//
//  DayRecipesTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import OpenAI
import Testing
@testable import MealPrep

struct DayRecipesTests {

    /// Regression guard, same class of failure as `PlanSkeleton`: schema
    /// derivation walks the example with runtime reflection, so an empty array
    /// or a non-`nonisolated` enum conformance compiles fine and fails only
    /// when a request is actually built.
    @Test func schemaDerivationSucceeds() throws {
        let encoded = try JSONEncoder().encode(JSONSchemaDefinition.derivedJsonSchema(DayRecipes.self))
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(json.contains("mealName"))
        #expect(json.contains("ingredientLines"))
        #expect(json.contains("steps"))
        #expect(json.contains("breakfast"))
    }

    @Test func exampleArraysAreAllNonEmpty() {
        #expect(!DayRecipes.example.meals.isEmpty)

        for meal in DayRecipes.example.meals {
            #expect(!meal.ingredientLines.isEmpty)
            #expect(!meal.steps.isEmpty)
        }
    }

    @Test func exampleCoversEverySlot() {
        let slots = Set(DayRecipes.example.meals.map(\.slot))
        #expect(slots == Set(MealSlot.allCases))
    }

    @Test func roundTripsThroughEncodingAndDecoding() throws {
        let data = try JSONEncoder().encode(DayRecipes.example)
        let decoded = try JSONDecoder().decode(DayRecipes.self, from: data)

        #expect(decoded == DayRecipes.example)
    }
}

struct RecipePromptBuilderTests {

    private let oats = Product.fixture(id: "oats", price: 2, grams: 1000)
    private let milk = Product(
        id: "milk",
        name: "Oat drink",
        departmentID: "bevande",
        categoryID: "en:plant-based-beverages",
        baseQuantity: .volume(milliliters: 1000),
        price: 2,
        nutrition: NutritionFacts(
            energyKcal: 50, proteins: 1, carbohydrates: 6, sugars: 3,
            fat: 1, saturatedFat: 0, fiber: 0, salt: 0.1
        ),
        labelIDs: [],
        allergenIDs: []
    )

    private func request(pantryItems: [String] = [], servings: Int = 1) -> RecipeRequest {
        let day = PlanSkeleton.Day(
            dayIndex: 2,
            meals: [
                .init(
                    slot: .breakfast,
                    name: "Overnight Oats",
                    prepTimeMinutes: 8,
                    ingredients: [
                        .init(productID: "oats", grams: 60),
                        .init(productID: "milk", grams: 200),
                    ],
                    pantryItems: pantryItems
                )
            ]
        )

        var configuration = MealPlanConfiguration.fixture()
        configuration.servings = servings

        return RecipeRequest(day: day, products: [oats, milk], configuration: configuration)
    }

    @Test func promptNamesProductsRatherThanRawIdentifiers() {
        let prompt = RecipePromptBuilder.userPrompt(for: request())

        #expect(prompt.contains("Test oats"))
        #expect(prompt.contains("Oat drink"))
    }

    @Test func quantitiesUseEachProductsOwnUnit() {
        let prompt = RecipePromptBuilder.userPrompt(for: request())

        #expect(prompt.contains("60 g"))
        #expect(prompt.contains("200 ml"))
    }

    @Test func promptCarriesTheMealNameSlotAndPrepTime() {
        let prompt = RecipePromptBuilder.userPrompt(for: request())

        #expect(prompt.contains("Overnight Oats"))
        #expect(prompt.contains("breakfast"))
        #expect(prompt.contains("8 minutes"))
    }

    @Test func pantryStaplesAreListedWithoutAQuantity() {
        let prompt = RecipePromptBuilder.userPrompt(for: request(pantryItems: [PantryStaple.salt.rawValue]))

        #expect(prompt.contains("already owned"))
        #expect(prompt.contains("salt"))
    }

    @Test func pantryLineIsOmittedWhenThereAreNoStaples() {
        let prompt = RecipePromptBuilder.userPrompt(for: request())

        #expect(!prompt.contains("already owned"))
    }

    @Test func promptStatesTheServingCount() {
        #expect(RecipePromptBuilder.userPrompt(for: request(servings: 1)).contains("1 serving"))
        #expect(RecipePromptBuilder.userPrompt(for: request(servings: 3)).contains("3 servings"))
    }

    @Test func systemPromptForbidsChangingTheShoppingList() {
        let prompt = RecipePromptBuilder.systemPrompt()

        #expect(prompt.contains("Never add, remove, or re-weigh"))
        #expect(prompt.contains("never substitute"))
    }
}
