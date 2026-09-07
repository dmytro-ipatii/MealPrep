//
//  IngredientUsage.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// One ingredient line as it appears in a single meal, before aggregation
/// across the week. `CostCalculator` groups these by product to compute the
/// basket — the real cost driver under whole-package costing is how many
/// distinct products the week touches, not how many grams each meal uses.
struct IngredientUsage: Sendable {
    let product: Product
    let quantity: Double
}
