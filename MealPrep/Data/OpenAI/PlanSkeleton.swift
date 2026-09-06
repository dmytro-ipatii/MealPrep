//
//  PlanSkeleton.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import OpenAI

/// The Pass A response contract: a structural meal plan skeleton (meals plus
/// `productID`s and quantities) with no recipe text yet. Cheap to validate
/// and repair; Pass B only spends tokens on prose once this is confirmed
/// valid. See app plan section 10.
///
/// `Ingredient.grams` is named after the plan's worked example, but holds the
/// quantity in whichever base unit the product actually uses (grams for mass
/// products, millilitres for volume products) — the catalog has both.
struct PlanSkeleton: JSONSchemaConvertible, Equatable {

    struct Ingredient: Codable, Sendable, Equatable {
        let productID: String
        let grams: Double
    }

    struct Meal: Codable, Sendable, Equatable {
        let slot: MealSlot
        let name: String
        let prepTimeMinutes: Int
        let ingredients: [Ingredient]
        /// `PantryStaple` raw values. Free, excluded from the budget.
        let pantryItems: [String]
    }

    struct Day: Codable, Sendable, Equatable {
        let dayIndex: Int
        let meals: [Meal]
    }

    let days: [Day]

    // Every array here must be non-empty — the schema is derived from this
    // instance, and an empty array yields a schema with no item type.
    static let example = PlanSkeleton(
        days: [
            Day(
                dayIndex: 0,
                meals: [
                    Meal(
                        slot: .breakfast,
                        name: "Porridge with Banana and Walnuts",
                        prepTimeMinutes: 8,
                        ingredients: [
                            Ingredient(productID: "example-oats", grams: 60),
                            Ingredient(productID: "example-banana", grams: 120),
                            Ingredient(productID: "example-walnuts", grams: 20),
                        ],
                        pantryItems: [PantryStaple.water.rawValue]
                    ),
                    Meal(
                        slot: .lunch,
                        name: "Chickpea and Tomato Salad",
                        prepTimeMinutes: 15,
                        ingredients: [
                            Ingredient(productID: "example-chickpeas", grams: 200),
                            Ingredient(productID: "example-tomatoes", grams: 150),
                            Ingredient(productID: "example-olive-oil", grams: 10),
                        ],
                        pantryItems: [PantryStaple.oliveOil.rawValue, PantryStaple.salt.rawValue]
                    ),
                    Meal(
                        slot: .dinner,
                        name: "Baked Salmon with Rice and Vegetables",
                        prepTimeMinutes: 35,
                        ingredients: [
                            Ingredient(productID: "example-salmon", grams: 180),
                            Ingredient(productID: "example-rice", grams: 90),
                            Ingredient(productID: "example-broccoli", grams: 120),
                        ],
                        pantryItems: [PantryStaple.oliveOil.rawValue, PantryStaple.blackPepper.rawValue]
                    ),
                ]
            )
        ]
    )
}

// `nonisolated` is load-bearing: this target defaults to MainActor isolation,
// which would make this an isolated conformance — and the OpenAI package
// derives the schema by dynamically casting to `JSONSchemaEnumConvertible`
// from nonisolated code, where an isolated conformance simply doesn't match.
extension MealSlot: nonisolated JSONSchemaEnumConvertible {
    nonisolated var caseNames: [String] { Self.allCases.map(\.rawValue) }
}
