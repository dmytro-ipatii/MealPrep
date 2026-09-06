//
//  GenerationError.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

enum GenerationError: Error, Sendable, Equatable {
    /// The budget floor for this configuration is above the user's budget.
    case budgetInfeasible(message: String)
    /// Repair ran out of moves and blocking violations remain. Never show the
    /// user an over-budget or diet-violating plan — fail instead.
    case couldNotSatisfyConstraints(violations: [PlanViolation])
    /// Pass B came back without prose for a meal. Section 14 requires every
    /// meal to have a non-empty recipe, so a half-written plan is not shippable.
    case missingRecipe(day: Int, slot: MealSlot)
}
