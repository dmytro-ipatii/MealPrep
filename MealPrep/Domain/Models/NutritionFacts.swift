//
//  NutritionFacts.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// Nutrition values per 100 g/ml of a product, as reported by the catalog.
///
/// Named `NutritionFacts` (not `Nutrition`) to avoid colliding with the
/// UI-facing `Nutrition` goal-selection enum in `Featrues/Screens/MealPlan`.
struct NutritionFacts: Sendable, Hashable {
    var energyKcal: Double
    var proteins: Double
    var carbohydrates: Double
    var sugars: Double
    var fat: Double
    var saturatedFat: Double
    var fiber: Double
    var salt: Double
}
