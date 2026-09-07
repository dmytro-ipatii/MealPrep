//
//  DayRecipes.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import OpenAI

/// The Pass B response contract: recipe prose for one already-validated day.
///
/// Pass B runs only after the skeleton is known good, so this call cannot
/// change what is bought — it adds words to a plan whose numbers are settled.
/// Recipes are matched back to meals by `slot`, never by array position.
struct DayRecipes: JSONSchemaConvertible, Equatable {

    struct MealRecipe: Codable, Sendable, Equatable {
        let slot: MealSlot
        let mealName: String
        let ingredientLines: [String]
        let steps: [String]
    }

    let meals: [MealRecipe]

    // Every array must be non-empty: the schema is derived from this instance,
    // and an empty array yields a schema with no item type.
    static let example = DayRecipes(
        meals: [
            MealRecipe(
                slot: .breakfast,
                mealName: "Porridge with Banana and Walnuts",
                ingredientLines: ["60 g rolled oats", "1 banana", "20 g walnuts", "300 ml water"],
                steps: [
                    "Bring the water to a simmer in a small saucepan.",
                    "Stir in the oats and cook for 5 minutes, stirring often.",
                    "Slice the banana and fold it through off the heat.",
                    "Top with the walnuts and serve warm.",
                ]
            ),
            MealRecipe(
                slot: .lunch,
                mealName: "Chickpea and Tomato Salad",
                ingredientLines: ["200 g chickpeas", "150 g tomatoes", "olive oil", "salt"],
                steps: [
                    "Drain and rinse the chickpeas.",
                    "Quarter the tomatoes and combine with the chickpeas.",
                    "Dress with olive oil, season with salt, and toss.",
                ]
            ),
            MealRecipe(
                slot: .dinner,
                mealName: "Baked Salmon with Rice and Broccoli",
                ingredientLines: ["180 g salmon fillet", "90 g rice", "120 g broccoli", "black pepper"],
                steps: [
                    "Heat the oven to 200°C.",
                    "Bake the salmon for 15 minutes until it flakes easily.",
                    "Meanwhile cook the rice, and steam the broccoli for 5 minutes.",
                    "Season with black pepper and serve together.",
                ]
            ),
        ]
    )
}
