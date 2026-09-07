//
//  StoredConfiguration.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import SwiftData

@Model
final class StoredConfiguration {
    var weeklyBudget: Decimal
    var currencyCode: String
    var dietaryNeedsRaw: [String]
    var goalsRaw: [String]
    var servings: Int
    var createdAt: Date

    init(configuration: MealPlanConfiguration) {
        self.weeklyBudget = configuration.weeklyBudget
        self.currencyCode = configuration.currencyCode
        self.dietaryNeedsRaw = configuration.dietaryNeeds.map(\.rawValue)
        self.goalsRaw = configuration.goals.map(\.rawValue)
        self.servings = configuration.servings
        self.createdAt = configuration.createdAt
    }

    func update(with configuration: MealPlanConfiguration) {
        weeklyBudget = configuration.weeklyBudget
        currencyCode = configuration.currencyCode
        dietaryNeedsRaw = configuration.dietaryNeeds.map(\.rawValue)
        goalsRaw = configuration.goals.map(\.rawValue)
        servings = configuration.servings
    }

    var asConfiguration: MealPlanConfiguration {
        MealPlanConfiguration(
            weeklyBudget: weeklyBudget,
            currencyCode: currencyCode,
            dietaryNeeds: Set(dietaryNeedsRaw.compactMap(DietaryNeed.init(rawValue:))),
            goals: Set(goalsRaw.compactMap(NutritionalGoal.init(rawValue:))),
            servings: servings,
            createdAt: createdAt
        )
    }
}
