//
//  FeasibilityChecker.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Precheck run on the candidate shortlist before any API call: is this
/// budget achievable at all? Failing fast here beats three failed repair
/// rounds ending in a degraded plan, and costs nothing.
enum FeasibilityChecker {

    static func checkFeasibility(
        candidates: [Product],
        configuration: MealPlanConfiguration
    ) -> FeasibilityResult {
        let minimumCost = minimumWeeklyCost(for: candidates)

        guard configuration.weeklyBudget >= minimumCost else {
            return .infeasible(
                minimumCost: minimumCost,
                message: message(minimumCost: minimumCost, configuration: configuration)
            )
        }

        return .feasible
    }

    /// Roughly: the minimum SKU set is one product per department, each
    /// taken at its cheapest candidate.
    static func minimumWeeklyCost(for candidates: [Product]) -> Decimal {
        Dictionary(grouping: candidates, by: \.departmentID)
            .values
            .compactMap { department in department.min(by: { $0.price < $1.price })?.price }
            .reduce(0, +)
    }

    private static func message(minimumCost: Decimal, configuration: MealPlanConfiguration) -> String {
        let amount = formattedAmount(minimumCost, currencyCode: configuration.currencyCode)
        let descriptors = descriptorList(for: configuration)

        guard let descriptors else {
            return "This week needs about \(amount) minimum with this catalogue. Try raising the budget."
        }

        return "A \(descriptors) week needs about \(amount) minimum with this catalogue. "
            + "Try raising the budget or relaxing one requirement."
    }

    private static func descriptorList(for configuration: MealPlanConfiguration) -> String? {
        let descriptors = configuration.dietaryNeeds.map(\.descriptor) + configuration.goals.map(\.descriptor)
        guard !descriptors.isEmpty else { return nil }
        return descriptors.sorted().joined(separator: ", ")
    }

    private static func formattedAmount(_ amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount) \(currencyCode)"
    }
}

private extension DietaryNeed {
    var descriptor: String {
        switch self {
        case .vegetarian: "vegetarian"
        case .vegan: "vegan"
        case .pescatarian: "pescatarian"
        case .glutenFree: "gluten-free"
        case .dairyFree: "dairy-free"
        }
    }
}

private extension NutritionalGoal {
    var descriptor: String {
        switch self {
        case .highProtein: "high-protein"
        case .lowSugar: "low-sugar"
        case .lowFat: "low-fat"
        case .lowCarbs: "low-carb"
        case .lowSalt: "low-salt"
        }
    }
}


