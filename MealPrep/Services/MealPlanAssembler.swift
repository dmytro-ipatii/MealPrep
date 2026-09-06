//
//  MealPlanAssembler.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Joins a validated skeleton, its recipe prose, and the priced basket into a
/// finished `MealPlan`. Every number here is computed in Swift; the model's
/// contribution is names and steps.
enum MealPlanAssembler {

    static func assemble(
        skeleton: PlanSkeleton,
        recipesByDay: [Int: DayRecipes],
        candidates: [Product],
        configuration: MealPlanConfiguration,
        generatedAt: Date
    ) throws -> MealPlan {
        let productsByID = Dictionary(
            candidates.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let basket = CostCalculator.basket(
            for: PlanValidator.usages(in: skeleton, productsByID: productsByID)
        )
        let linesByProductID = Dictionary(
            basket.lines.map { ($0.product.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        let days = try skeleton.days
            .sorted { $0.dayIndex < $1.dayIndex }
            .map { day in
                PlanDay(
                    dayIndex: day.dayIndex,
                    meals: try day.meals.map { meal in
                        try plannedMeal(
                            meal,
                            dayIndex: day.dayIndex,
                            recipes: recipesByDay[day.dayIndex],
                            productsByID: productsByID,
                            linesByProductID: linesByProductID,
                            servings: configuration.servings
                        )
                    }
                )
            }

        return MealPlan(
            generatedAt: generatedAt,
            configuration: configuration,
            days: days,
            basket: basket
        )
    }

    private static func plannedMeal(
        _ meal: PlanSkeleton.Meal,
        dayIndex: Int,
        recipes: DayRecipes?,
        productsByID: [String: Product],
        linesByProductID: [String: BasketLine],
        servings: Int
    ) throws -> PlannedMeal {
        // Matched by slot, never by array position — the model is free to
        // return the meals in any order.
        guard
            let mealRecipe = recipes?.meals.first(where: { $0.slot == meal.slot }),
            !mealRecipe.steps.isEmpty
        else {
            throw GenerationError.missingRecipe(day: dayIndex, slot: meal.slot)
        }

        let ingredients = meal.ingredients.compactMap { ingredient -> MealIngredient? in
            guard let product = productsByID[ingredient.productID] else { return nil }

            return MealIngredient(
                productID: product.id,
                productName: product.name,
                quantity: ingredient.grams,
                unit: product.baseQuantity.unitLabel,
                costShare: costShare(
                    quantity: ingredient.grams,
                    line: linesByProductID[product.id]
                )
            )
        }

        return PlannedMeal(
            slot: meal.slot,
            name: mealRecipe.mealName.isEmpty ? meal.name : mealRecipe.mealName,
            prepTimeMinutes: meal.prepTimeMinutes,
            servings: servings,
            ingredients: ingredients,
            pantryItems: meal.pantryItems.compactMap(PantryStaple.init(rawValue:)),
            recipe: Recipe(
                ingredientLines: mealRecipe.ingredientLines,
                steps: mealRecipe.steps
            )
        )
    }

    /// A meal has no standalone price under whole-package costing, so it gets
    /// the share of the package its portion represents.
    private static func costShare(quantity: Double, line: BasketLine?) -> Decimal {
        guard let line, line.requiredQuantity > 0 else { return 0 }
        return line.cost * Decimal(quantity / line.requiredQuantity)
    }
}
