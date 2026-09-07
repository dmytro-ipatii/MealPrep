//
//  PlanViolation.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Everything that can be wrong with a generated plan skeleton.
///
/// The last three cases are an amendment to app plan section 11: section 14
/// requires 7 days × 3 meals with at least 2 ingredients per meal, but the
/// original enum had no way to report a structurally incomplete plan.
nonisolated enum PlanViolation: Sendable, Equatable {
    case unknownProduct(id: String, day: Int, slot: MealSlot)
    case dietaryViolation(productID: String, need: DietaryNeed)
    case pantryItemNotRecognized(String)
    case stapleDuplicatedAsIngredient(productID: String)
    case implausibleQuantity(productID: String, grams: Double)
    case overBudget(computed: Decimal, limit: Decimal)
    case skuCountExceeded(count: Int, limit: Int)
    case goalMissed(goal: NutritionalGoal, day: Int, value: Double)

    case missingDay(dayIndex: Int)
    case missingMeal(day: Int, slot: MealSlot)
    case tooFewIngredients(day: Int, slot: MealSlot, count: Int)

    /// A blocking violation must never reach the user — an over-budget or
    /// diet-violating plan is not shippable. `goalMissed` is advisory: a
    /// nutritional goal is a soft preference, and failing one is not a reason
    /// to show the user nothing at all.
    var isBlocking: Bool {
        switch self {
        case .goalMissed: false
        default: true
        }
    }
}

extension PlanViolation: CustomStringConvertible {
    var description: String {
        switch self {
        case .unknownProduct(let id, let day, let slot):
            "Day \(day) \(slot.rawValue): productID '\(id)' is not in the candidate list."
        case .dietaryViolation(let productID, let need):
            "Product '\(productID)' violates the \(need.rawValue) requirement."
        case .pantryItemNotRecognized(let item):
            "'\(item)' is not a recognized pantry staple."
        case .stapleDuplicatedAsIngredient(let productID):
            "Product '\(productID)' duplicates a free pantry staple and must not be bought."
        case .implausibleQuantity(let productID, let grams):
            "Quantity \(grams.formatted()) for product '\(productID)' is not plausible for one serving."
        case .overBudget(let computed, let limit):
            "The basket costs \(computed) but the budget is \(limit)."
        case .skuCountExceeded(let count, let limit):
            "The plan uses \(count) distinct products but the limit is \(limit)."
        case .goalMissed(let goal, let day, let value):
            "Day \(day) misses the \(goal.rawValue) goal (daily total \(value.formatted()))."
        case .missingDay(let dayIndex):
            "Day \(dayIndex) is missing from the plan."
        case .missingMeal(let day, let slot):
            "Day \(day) is missing its \(slot.rawValue)."
        case .tooFewIngredients(let day, let slot, let count):
            "Day \(day) \(slot.rawValue) has only \(count) ingredient(s); at least 2 are required."
        }
    }
}
