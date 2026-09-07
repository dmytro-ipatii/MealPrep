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
    /// Builds the recipe response for a day. Defaults to full coverage.
    var recipeProvider: @Sendable (RecipeRequest) throws -> DayRecipes

    private let queue = DispatchQueue(label: "StubMealPlanLLMClient")
    private var _generateCallCount = 0
    private var _repairCallCount = 0
    private var _repairRequests: [PlanRepairRequest] = []
    private var _recipeRequests: [RecipeRequest] = []
    private var _peakConcurrentRecipeCalls = 0
    private var _inFlightRecipeCalls = 0

    var generateCallCount: Int { queue.sync { _generateCallCount } }
    var repairCallCount: Int { queue.sync { _repairCallCount } }
    var repairRequests: [PlanRepairRequest] { queue.sync { _repairRequests } }
    var recipeRequests: [RecipeRequest] { queue.sync { _recipeRequests } }
    var recipeCallCount: Int { queue.sync { _recipeRequests.count } }
    var peakConcurrentRecipeCalls: Int { queue.sync { _peakConcurrentRecipeCalls } }

    init(generate: PlanSkeleton, repairs: [PlanSkeleton] = []) {
        self.generateResult = .success(generate)
        self.repairResults = repairs
        self.recipeProvider = { request in .covering(request.day) }
    }

    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton {
        queue.sync { _generateCallCount += 1 }
        return try generateResult.get()
    }

    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton {
        let index: Int = queue.sync {
            _repairRequests.append(request)
            defer { _repairCallCount += 1 }
            return _repairCallCount
        }

        guard !repairResults.isEmpty else { return request.skeleton }
        return repairResults[min(index, repairResults.count - 1)]
    }

    func generateRecipes(_ request: RecipeRequest) async throws -> DayRecipes {
        queue.sync {
            _recipeRequests.append(request)
            _inFlightRecipeCalls += 1
            _peakConcurrentRecipeCalls = max(_peakConcurrentRecipeCalls, _inFlightRecipeCalls)
        }
        defer { queue.sync { _inFlightRecipeCalls -= 1 } }

        // Yield so genuinely concurrent callers overlap and the peak counter
        // measures something real.
        await Task.yield()

        return try recipeProvider(request)
    }
}

extension DayRecipes {
    /// A recipe for every meal in the given day, so assembly succeeds.
    static func covering(_ day: PlanSkeleton.Day) -> DayRecipes {
        DayRecipes(
            meals: day.meals.map { meal in
                MealRecipe(
                    slot: meal.slot,
                    mealName: meal.name,
                    ingredientLines: meal.ingredients.map { "\($0.grams.formatted()) of \($0.productID)" },
                    steps: ["Prepare the ingredients.", "Cook and serve."]
                )
            }
        )
    }
}
