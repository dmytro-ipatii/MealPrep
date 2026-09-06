//
//  Recipe.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// The prose half of a meal — the one thing the model is genuinely good at.
struct Recipe: Sendable, Equatable {
    /// Readable ingredient lines, e.g. "200 g penne". Presentation only: the
    /// authoritative quantities live in `PlannedMeal.ingredients`.
    let ingredientLines: [String]
    let steps: [String]

    var isEmpty: Bool { steps.isEmpty }
}
