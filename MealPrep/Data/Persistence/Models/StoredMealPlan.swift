//
//  StoredMealPlan.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation
import SwiftData

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
