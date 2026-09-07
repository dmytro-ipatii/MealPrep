//
//  PlanValidator.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Checks a generated plan skeleton against everything that must be *correct*:
/// product identity, dietary safety, pantry rules, quantities, cost, SKU count,
/// structure, and nutritional direction. A pure function — no I/O.
///
/// This is the backstop. Dietary filtering already ran before candidate
/// selection, so the model physically could not pick an unsafe product; this
/// re-checks anyway, because "the model was only shown safe products" is an
/// assumption and allergen exclusion is safety critical.
nonisolated enum PlanValidator {

    /// Plausible single-serving quantity bounds, in the product's base unit.
    /// A demo-grade heuristic — the catalog has no serving-size field.
    static let minimumPlausibleQuantity: Double = 1
    static let maximumPlausibleQuantity: Double = 1500

    static func validate(
        _ skeleton: PlanSkeleton,
        candidates: [Product],
        configuration: MealPlanConfiguration,
        expectedDayCount: Int,
        skuLimit: Int
    ) -> [PlanViolation] {
        let productsByID = Dictionary(candidates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var violations: [PlanViolation] = []
        violations += structuralViolations(skeleton, expectedDayCount: expectedDayCount)
        violations += ingredientViolations(skeleton, productsByID: productsByID, configuration: configuration)
        violations += pantryViolations(skeleton)
        violations += basketViolations(skeleton, productsByID: productsByID, configuration: configuration, skuLimit: skuLimit)
        violations += goalViolations(skeleton, productsByID: productsByID, configuration: configuration)
        return violations
    }

    // MARK: - Structure

    private static func structuralViolations(
        _ skeleton: PlanSkeleton,
        expectedDayCount: Int
    ) -> [PlanViolation] {
        var violations: [PlanViolation] = []
        let daysByIndex = Dictionary(skeleton.days.map { ($0.dayIndex, $0) }, uniquingKeysWith: { first, _ in first })

        for dayIndex in 0..<expectedDayCount {
            guard let day = daysByIndex[dayIndex] else {
                violations.append(.missingDay(dayIndex: dayIndex))
                continue
            }

            for slot in MealSlot.allCases {
                guard let meal = day.meals.first(where: { $0.slot == slot }) else {
                    violations.append(.missingMeal(day: dayIndex, slot: slot))
                    continue
                }

                if meal.ingredients.count < 2 {
                    violations.append(
                        .tooFewIngredients(day: dayIndex, slot: slot, count: meal.ingredients.count)
                    )
                }
            }
        }

        return violations
    }

    // MARK: - Ingredients

    private static func ingredientViolations(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        configuration: MealPlanConfiguration
    ) -> [PlanViolation] {
        var violations: [PlanViolation] = []
        var checkedProductIDs = Set<String>()

        for day in skeleton.days {
            for meal in day.meals {
                for ingredient in meal.ingredients {
                    guard let product = productsByID[ingredient.productID] else {
                        violations.append(
                            .unknownProduct(id: ingredient.productID, day: day.dayIndex, slot: meal.slot)
                        )
                        continue
                    }

                    if ingredient.grams < minimumPlausibleQuantity || ingredient.grams > maximumPlausibleQuantity {
                        violations.append(
                            .implausibleQuantity(productID: product.id, grams: ingredient.grams)
                        )
                    }

                    guard checkedProductIDs.insert(product.id).inserted else { continue }

                    for need in configuration.dietaryNeeds.sorted(by: { $0.rawValue < $1.rawValue })
                    where !DietaryFilterService.isSafe(product, for: need) {
                        violations.append(.dietaryViolation(productID: product.id, need: need))
                    }

                    if PantryStaple.duplicatesAStaple(categoryID: product.categoryID) {
                        violations.append(.stapleDuplicatedAsIngredient(productID: product.id))
                    }
                }
            }
        }

        return violations
    }

    private static func pantryViolations(_ skeleton: PlanSkeleton) -> [PlanViolation] {
        var seen = Set<String>()
        return skeleton.days
            .flatMap { $0.meals.flatMap(\.pantryItems) }
            .filter { PantryStaple(rawValue: $0) == nil && seen.insert($0).inserted }
            .map { .pantryItemNotRecognized($0) }
    }

    // MARK: - Cost

    private static func basketViolations(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        configuration: MealPlanConfiguration,
        skuLimit: Int
    ) -> [PlanViolation] {
        let basket = CostCalculator.basket(for: usages(in: skeleton, productsByID: productsByID))

        var violations: [PlanViolation] = []

        if basket.totalCost > configuration.weeklyBudget {
            violations.append(.overBudget(computed: basket.totalCost, limit: configuration.weeklyBudget))
        }

        if basket.skuCount > skuLimit {
            violations.append(.skuCountExceeded(count: basket.skuCount, limit: skuLimit))
        }

        return violations
    }

    // MARK: - Nutritional goals

    /// Daily reference values for one person. Demo-grade thresholds, chosen so
    /// "moves in the direction of the goal" is a checkable statement rather
    /// than a vibe. Goals are evaluated per day, never per meal.
    static func dailyGoalIsMet(_ goal: NutritionalGoal, dailyTotal: Double) -> Bool {
        switch goal {
        case .highProtein: dailyTotal >= 60
        case .lowSugar: dailyTotal <= 60
        case .lowFat: dailyTotal <= 70
        case .lowCarbs: dailyTotal <= 150
        case .lowSalt: dailyTotal <= 6
        }
    }

    static func dailyTotal(_ goal: NutritionalGoal, for day: PlanSkeleton.Day, productsByID: [String: Product]) -> Double {
        day.meals
            .flatMap(\.ingredients)
            .reduce(0) { total, ingredient in
                guard let product = productsByID[ingredient.productID] else { return total }
                let factor = ingredient.grams / 100
                let nutrition = product.nutrition

                let per100: Double = switch goal {
                case .highProtein: nutrition.proteins
                case .lowSugar: nutrition.sugars
                case .lowFat: nutrition.fat + nutrition.saturatedFat
                case .lowCarbs: nutrition.carbohydrates
                case .lowSalt: nutrition.salt
                }

                return total + per100 * factor
            }
    }

    private static func goalViolations(
        _ skeleton: PlanSkeleton,
        productsByID: [String: Product],
        configuration: MealPlanConfiguration
    ) -> [PlanViolation] {
        guard !configuration.goals.isEmpty else { return [] }

        var violations: [PlanViolation] = []
        for day in skeleton.days.sorted(by: { $0.dayIndex < $1.dayIndex }) {
            for goal in configuration.goals.sorted(by: { $0.rawValue < $1.rawValue }) {
                let total = dailyTotal(goal, for: day, productsByID: productsByID)
                if !dailyGoalIsMet(goal, dailyTotal: total) {
                    violations.append(.goalMissed(goal: goal, day: day.dayIndex, value: total))
                }
            }
        }
        return violations
    }

    // MARK: - Shared

    static func usages(in skeleton: PlanSkeleton, productsByID: [String: Product]) -> [IngredientUsage] {
        skeleton.days
            .flatMap { $0.meals.flatMap(\.ingredients) }
            .compactMap { ingredient in
                productsByID[ingredient.productID].map {
                    IngredientUsage(product: $0, quantity: ingredient.grams)
                }
            }
    }
}
