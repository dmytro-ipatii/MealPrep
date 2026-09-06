//
//  PlanFixtures.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
@testable import MealPrep

extension Product {
    static func fixture(
        id: String,
        categoryID: String = "en:test-category",
        departmentID: String = "dispensa",
        price: Double = 1,
        grams: Double = 1000,
        proteins: Double = 10,
        sugars: Double = 1,
        fat: Double = 1,
        saturatedFat: Double = 0.5,
        carbohydrates: Double = 10,
        salt: Double = 0.1,
        labelIDs: Set<String> = [],
        allergenIDs: Set<String> = []
    ) -> Product {
        Product(
            id: id,
            name: "Test \(id)",
            departmentID: departmentID,
            categoryID: categoryID,
            baseQuantity: .mass(grams: grams),
            price: Decimal(price),
            nutrition: NutritionFacts(
                energyKcal: 100,
                proteins: proteins,
                carbohydrates: carbohydrates,
                sugars: sugars,
                fat: fat,
                saturatedFat: saturatedFat,
                fiber: 1,
                salt: salt
            ),
            labelIDs: labelIDs,
            allergenIDs: allergenIDs
        )
    }
}

extension MealPlanConfiguration {
    static func fixture(
        weeklyBudget: Double = 70,
        dietaryNeeds: Set<DietaryNeed> = [],
        goals: Set<NutritionalGoal> = []
    ) -> MealPlanConfiguration {
        MealPlanConfiguration(
            weeklyBudget: Decimal(weeklyBudget),
            currencyCode: "EUR",
            dietaryNeeds: dietaryNeeds,
            goals: goals,
            servings: 1,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}

extension PlanSkeleton {
    /// A structurally complete week: every day, every slot, two ingredients
    /// each, drawn by rotating through `productIDs`.
    static func week(
        productIDs: [String],
        grams: Double = 100,
        dayCount: Int = MealPlanGenerator.daysPerPlan
    ) -> PlanSkeleton {
        var cursor = 0
        func nextID() -> String {
            defer { cursor += 1 }
            return productIDs[cursor % productIDs.count]
        }

        let days = (0..<dayCount).map { dayIndex in
            Day(
                dayIndex: dayIndex,
                meals: MealSlot.allCases.map { slot in
                    var ingredients: [Ingredient] = []
                    var seen = Set<String>()
                    while ingredients.count < 2 {
                        let id = nextID()
                        guard seen.insert(id).inserted else { continue }
                        ingredients.append(Ingredient(productID: id, grams: grams))
                    }
                    return Meal(
                        slot: slot,
                        name: "Day \(dayIndex) \(slot.rawValue)",
                        prepTimeMinutes: 10,
                        ingredients: ingredients,
                        pantryItems: [PantryStaple.salt.rawValue]
                    )
                }
            )
        }

        return PlanSkeleton(days: days)
    }

    /// One day, one meal — the smallest skeleton that still parses. Useful for
    /// exercising a single validation rule without a week of noise around it.
    static func singleMeal(
        ingredients: [Ingredient],
        slot: MealSlot = .breakfast,
        pantryItems: [String] = []
    ) -> PlanSkeleton {
        PlanSkeleton(
            days: [
                Day(
                    dayIndex: 0,
                    meals: [
                        Meal(
                            slot: slot,
                            name: "Test meal",
                            prepTimeMinutes: 10,
                            ingredients: ingredients,
                            pantryItems: pantryItems
                        )
                    ]
                )
            ]
        )
    }

    /// Swaps the first ingredient of the first meal, so a test can plant one
    /// specific product in a known position.
    func replacingFirstIngredient(with productID: String) -> PlanSkeleton {
        var days = self.days
        let firstDay = days[0]
        var meals = firstDay.meals
        let firstMeal = meals[0]
        var ingredients = firstMeal.ingredients
        ingredients[0] = Ingredient(productID: productID, grams: ingredients[0].grams)

        meals[0] = Meal(
            slot: firstMeal.slot,
            name: firstMeal.name,
            prepTimeMinutes: firstMeal.prepTimeMinutes,
            ingredients: ingredients,
            pantryItems: firstMeal.pantryItems
        )
        days[0] = Day(dayIndex: firstDay.dayIndex, meals: meals)

        return PlanSkeleton(days: days)
    }

    var allIngredients: [Ingredient] {
        days.flatMap { $0.meals.flatMap(\.ingredients) }
    }

    var distinctProductIDs: Set<String> {
        Set(allIngredients.map(\.productID))
    }
}

/// Records what the pipeline asked for and replays canned responses, so the
/// whole generate → validate → repair loop is testable with no network.
final class StubMealPlanLLMClient: MealPlanLLMClient, @unchecked Sendable {
    var generateResult: Result<PlanSkeleton, Error>
    /// Consumed in order; the last one repeats once exhausted.
    var repairResults: [PlanSkeleton]

    private(set) var generateCallCount = 0
    private(set) var repairCallCount = 0
    private(set) var repairRequests: [PlanRepairRequest] = []

    init(generate: PlanSkeleton, repairs: [PlanSkeleton] = []) {
        self.generateResult = .success(generate)
        self.repairResults = repairs
    }

    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton {
        generateCallCount += 1
        return try generateResult.get()
    }

    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton {
        repairRequests.append(request)
        defer { repairCallCount += 1 }

        guard !repairResults.isEmpty else { return request.skeleton }
        return repairResults[min(repairCallCount, repairResults.count - 1)]
    }
}
