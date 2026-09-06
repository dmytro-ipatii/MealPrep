//
//  MealPlan.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// A finished, validated 7-day plan: meals with recipes, a priced basket, and
/// the configuration it was generated for. Everything numeric here was
/// computed in Swift — the model contributed names and prose only.
struct MealPlan: Sendable, Equatable {
    let generatedAt: Date
    let configuration: MealPlanConfiguration
    let days: [PlanDay]
    /// Snapshotted, so a stored plan still renders after the bundled catalog
    /// changes. See `ShoppingLine`.
    let shoppingList: [ShoppingLine]

    var totalCost: Decimal { shoppingList.reduce(0) { $0 + $1.cost } }
    var totalWasteQuantity: Double { shoppingList.reduce(0) { $0 + $1.wasteQuantity } }
    var skuCount: Int { shoppingList.count }
}

struct PlanDay: Sendable, Equatable {
    let dayIndex: Int
    let meals: [PlannedMeal]
}

/// Named `PlannedMeal`, not `Meal`, because `PlanSkeleton.Meal` already exists
/// as the wire-format type. An unqualified `Meal` would resolve to different
/// types depending on the file, which is precisely the kind of silent
/// shadowing that is painful to debug.
struct PlannedMeal: Sendable, Equatable {
    let slot: MealSlot
    let name: String
    let prepTimeMinutes: Int
    let servings: Int
    let ingredients: [MealIngredient]
    let pantryItems: [PantryStaple]
    let recipe: Recipe

    /// This meal's share of the weekly basket. Under whole-package costing a
    /// meal has no standalone price, so this is the product's package cost
    /// split across the meals that use it, by quantity.
    var estimatedCost: Decimal {
        ingredients.reduce(0) { $0 + $1.costShare }
    }
}

struct MealIngredient: Sendable, Equatable {
    let productID: String
    /// Snapshotted so an old plan still renders if the catalog file changes.
    let productName: String
    let quantity: Double
    let unit: String
    let costShare: Decimal
}
