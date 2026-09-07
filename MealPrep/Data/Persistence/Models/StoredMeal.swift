//
//  StoredMeal.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation
import SwiftData

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
