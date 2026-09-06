//
//  PlanSkeletonTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import OpenAI
import Testing
@testable import MealPrep

struct PlanSkeletonTests {

    @Test func exampleRoundTripsThroughEncodingAndDecoding() throws {
        let data = try JSONEncoder().encode(PlanSkeleton.example)
        let decoded = try JSONDecoder().decode(PlanSkeleton.self, from: data)

        #expect(decoded == PlanSkeleton.example)
    }

    @Test func exampleArraysAreAllNonEmpty() {
        // Required by the OpenAI package: an empty array in `example` yields
        // a schema with no item type.
        let example = PlanSkeleton.example
        #expect(!example.days.isEmpty)

        for day in example.days {
            #expect(!day.meals.isEmpty)
            for meal in day.meals {
                #expect(!meal.ingredients.isEmpty)
            }
        }
    }

    @Test func exampleCoversAllThreeMealSlots() {
        let slots = Set(PlanSkeleton.example.days.flatMap { $0.meals.map(\.slot) })
        #expect(slots == Set(MealSlot.allCases))
    }

    @Test func exampleUsesOnlyRealPantryStaples() {
        let allPantryItems = PlanSkeleton.example.days.flatMap { $0.meals.flatMap(\.pantryItems) }
        #expect(allPantryItems.allSatisfy { raw in PantryStaple(rawValue: raw) != nil })
    }

    @Test func mealSlotCaseNamesMatchAllCases() {
        #expect(Set(MealSlot.breakfast.caseNames) == Set(MealSlot.allCases.map(\.rawValue)))
    }

    /// Regression guard: `MealSlot`'s `JSONSchemaEnumConvertible` conformance
    /// must stay `nonisolated`. This target defaults to MainActor isolation,
    /// and an isolated conformance fails the dynamic cast the OpenAI package
    /// uses to derive the schema — which compiles fine and only fails at
    /// runtime, with `.enumsConformance`.
    @Test func schemaDerivationSucceedsForTheWholeSkeleton() throws {
        let encoded = try JSONEncoder().encode(JSONSchemaDefinition.derivedJsonSchema(PlanSkeleton.self))
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(json.contains("days"))
        #expect(json.contains("breakfast"))
        #expect(json.contains("productID"))
    }

    @Test func decodingArbitraryValidJSONProducesExpectedStructure() throws {
        let json = """
        {
            "days": [
                {
                    "dayIndex": 2,
                    "meals": [
                        {
                            "slot": "lunch",
                            "name": "Pasta with Tomato Sauce",
                            "prepTimeMinutes": 20,
                            "ingredients": [
                                { "productID": "abc123", "grams": 100 }
                            ],
                            "pantryItems": ["oliveOil"]
                        }
                    ]
                }
            ]
        }
        """

        let decoded = try JSONDecoder().decode(PlanSkeleton.self, from: Data(json.utf8))

        #expect(decoded.days.count == 1)
        #expect(decoded.days[0].dayIndex == 2)
        #expect(decoded.days[0].meals[0].slot == .lunch)
        #expect(decoded.days[0].meals[0].ingredients[0].productID == "abc123")
    }
}
