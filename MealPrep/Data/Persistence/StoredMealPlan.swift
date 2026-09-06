//
//  StoredMealPlan.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import SwiftData

/// The persisted form of a finished plan (app plan section 5.4).
///
/// Everything the UI needs is snapshotted here — product names, quantities,
/// prices — so a stored plan renders correctly even after the bundled catalog
/// changes. Nothing here needs to resolve against `product_catalog_en.json`.
@Model
final class StoredMealPlan {
    var generatedAt: Date
    var totalCost: Decimal
    var totalWasteQuantity: Double

    @Relationship(deleteRule: .cascade) var days: [StoredPlanDay]
    @Relationship(deleteRule: .cascade) var shoppingList: [StoredShoppingLine]

    /// The configuration this plan was generated for, denormalized rather than
    /// held as a `StoredConfiguration` relationship (app plan section 5.4).
    /// `ConfigurationStore` keeps exactly one `StoredConfiguration` row and
    /// reads it with `fetch().first`, so a per-plan snapshot row would let the
    /// user's live settings resolve to a frozen copy from an old plan.
    var weeklyBudget: Decimal
    var currencyCode: String
    var dietaryNeedsRaw: [String]
    var goalsRaw: [String]
    var servings: Int
    /// When the *configuration* was created, which is not when the plan was
    /// generated — a plan can be regenerated from settings saved days earlier.
    var configurationCreatedAt: Date

    init(
        generatedAt: Date,
        totalCost: Decimal,
        totalWasteQuantity: Double,
        days: [StoredPlanDay],
        shoppingList: [StoredShoppingLine],
        weeklyBudget: Decimal,
        currencyCode: String,
        dietaryNeedsRaw: [String],
        goalsRaw: [String],
        servings: Int,
        configurationCreatedAt: Date
    ) {
        self.generatedAt = generatedAt
        self.totalCost = totalCost
        self.totalWasteQuantity = totalWasteQuantity
        self.days = days
        self.shoppingList = shoppingList
        self.weeklyBudget = weeklyBudget
        self.currencyCode = currencyCode
        self.dietaryNeedsRaw = dietaryNeedsRaw
        self.goalsRaw = goalsRaw
        self.servings = servings
        self.configurationCreatedAt = configurationCreatedAt
    }
}

@Model
final class StoredPlanDay {
    var dayIndex: Int
    @Relationship(deleteRule: .cascade) var meals: [StoredMeal]

    init(dayIndex: Int, meals: [StoredMeal]) {
        self.dayIndex = dayIndex
        self.meals = meals
    }
}

@Model
final class StoredMeal {
    var slotRaw: String
    var name: String
    var prepTimeMinutes: Int
    var servings: Int
    var estimatedCost: Decimal
    /// Stored as the two arrays Pass B actually returns rather than the
    /// `recipeMarkdown` string in app plan section 5.4 — SwiftData persists
    /// `[String]` natively, and round-tripping markdown back into steps would
    /// be lossy parsing for no benefit.
    var recipeIngredientLines: [String]
    var recipeSteps: [String]
    var pantryItemsRaw: [String]

    @Relationship(deleteRule: .cascade) var ingredients: [StoredIngredient]

    init(
        slotRaw: String,
        name: String,
        prepTimeMinutes: Int,
        servings: Int,
        estimatedCost: Decimal,
        recipeIngredientLines: [String],
        recipeSteps: [String],
        pantryItemsRaw: [String],
        ingredients: [StoredIngredient]
    ) {
        self.slotRaw = slotRaw
        self.name = name
        self.prepTimeMinutes = prepTimeMinutes
        self.servings = servings
        self.estimatedCost = estimatedCost
        self.recipeIngredientLines = recipeIngredientLines
        self.recipeSteps = recipeSteps
        self.pantryItemsRaw = pantryItemsRaw
        self.ingredients = ingredients
    }
}

@Model
final class StoredIngredient {
    /// SwiftData relationship arrays come back unordered, so the order the
    /// model listed the ingredients in — which the recipe lines follow — has
    /// to be stored explicitly.
    var position: Int
    var productID: String
    var productNameSnapshot: String
    var quantityValue: Double
    var quantityUnit: String
    var costShare: Decimal

    init(
        position: Int,
        productID: String,
        productNameSnapshot: String,
        quantityValue: Double,
        quantityUnit: String,
        costShare: Decimal
    ) {
        self.position = position
        self.productID = productID
        self.productNameSnapshot = productNameSnapshot
        self.quantityValue = quantityValue
        self.quantityUnit = quantityUnit
        self.costShare = costShare
    }
}

@Model
final class StoredShoppingLine {
    var productID: String
    var productNameSnapshot: String
    var packages: Int
    var requiredQuantity: Double
    var purchasedQuantity: Double
    var quantityUnit: String
    var cost: Decimal

    init(
        productID: String,
        productNameSnapshot: String,
        packages: Int,
        requiredQuantity: Double,
        purchasedQuantity: Double,
        quantityUnit: String,
        cost: Decimal
    ) {
        self.productID = productID
        self.productNameSnapshot = productNameSnapshot
        self.packages = packages
        self.requiredQuantity = requiredQuantity
        self.purchasedQuantity = purchasedQuantity
        self.quantityUnit = quantityUnit
        self.cost = cost
    }
}
