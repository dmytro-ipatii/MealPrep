//
//  MealPlanConfiguration.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

nonisolated  struct MealPlanConfiguration: Sendable, Equatable {
    var weeklyBudget: Decimal
    var currencyCode: String
    var dietaryNeeds: Set<DietaryNeed>
    var goals: Set<NutritionalGoal>
    var servings: Int
    var createdAt: Date
}
