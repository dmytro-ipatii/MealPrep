//
//  RecipePromptBuilder.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Builds the Pass B prompt: recipe prose for one validated day.
///
/// By this point the plan's numbers are settled and checked, so the only job
/// left is writing. The prompt says so explicitly — the model must not add,
/// drop, or re-weigh anything, because nothing downstream re-validates the
/// quantities it writes into `ingredientLines`.
enum RecipePromptBuilder {

    static func systemPrompt() -> String {
        """
        You are a recipe writer. You are given a fixed set of meals with exact \
        ingredients and quantities that have already been costed and checked. \
        Write clear, appealing, step-by-step instructions for them. Never add, \
        remove, or re-weigh an ingredient, and never substitute one for \
        another — the shopping is already done.
        """
    }

    static func userPrompt(for request: RecipeRequest) -> String {
        let productsByID = Dictionary(
            request.products.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let meals = request.day.meals
            .map { mealDescription($0, productsByID: productsByID) }
            .joined(separator: "\n\n")

        return """
        Write recipes for the \(request.day.meals.count) meals below. Return one \
        entry per meal, matching each to its slot.

        For each meal:
        - mealName: keep the given name unless it is a poor fit for the \
        ingredients, in which case improve it.
        - ingredientLines: one readable line per ingredient, restating the \
        quantity exactly as given (pantry staples may be listed without a \
        quantity, e.g. "salt").
        - steps: the preparation, in order. Fit the stated prep time. Assume a \
        basic home kitchen. Do not number the steps — each entry is one step.

        Cook for \(request.configuration.servings) serving\(request.configuration.servings == 1 ? "" : "s").

        \(meals)
        """
    }

    private static func mealDescription(
        _ meal: PlanSkeleton.Meal,
        productsByID: [String: Product]
    ) -> String {
        let ingredients = meal.ingredients.map { ingredient -> String in
            guard let product = productsByID[ingredient.productID] else {
                return "- \(ingredient.productID): \(ingredient.grams.formatted())"
            }
            return "- \(product.name): \(ingredient.grams.formatted()) \(product.baseQuantity.unitLabel)"
        }

        var lines = [
            "\(meal.slot.rawValue) — \"\(meal.name)\", about \(meal.prepTimeMinutes) minutes",
            "Ingredients:",
        ]
        lines += ingredients

        if !meal.pantryItems.isEmpty {
            let staples = meal.pantryItems
                .compactMap { PantryStaple(rawValue: $0)?.rawValue }
                .joined(separator: ", ")
            lines.append("From the pantry (already owned, no quantity needed): \(staples)")
        }

        return lines.joined(separator: "\n")
    }
}
