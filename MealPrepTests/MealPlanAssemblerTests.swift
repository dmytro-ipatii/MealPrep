//
//  MealPlanAssemblerTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct MealPlanAssemblerTests {

    private let products = (0..<6).map { Product.fixture(id: "p\($0)", price: 2, grams: 1000) }

    private func assemble(
        _ skeleton: PlanSkeleton,
        recipes: [Int: DayRecipes]? = nil,
        products: [Product]? = nil,
        configuration: MealPlanConfiguration = .fixture()
    ) throws -> MealPlan {
        let skeletonProducts = products ?? self.products
        let resolvedRecipes = recipes ?? Dictionary(
            uniqueKeysWithValues: skeleton.days.map { ($0.dayIndex, DayRecipes.covering($0)) }
        )

        return try MealPlanAssembler.assemble(
            skeleton: skeleton,
            recipesByDay: resolvedRecipes,
            candidates: skeletonProducts,
            configuration: configuration,
            generatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func producesAFullWeekOfMealsWithRecipes() throws {
        let plan = try assemble(PlanSkeleton.week(productIDs: products.map(\.id)))

        #expect(plan.days.count == 7)
        #expect(plan.days.allSatisfy { $0.meals.count == 3 })

        let everyMealHasSteps = plan.days
            .flatMap(\.meals)
            .allSatisfy { !$0.recipe.isEmpty }
        #expect(everyMealHasSteps)
    }

    @Test func daysComeBackInOrderRegardlessOfSkeletonOrdering() throws {
        let ordered = PlanSkeleton.week(productIDs: products.map(\.id))
        let shuffled = PlanSkeleton(days: ordered.days.reversed())

        let plan = try assemble(shuffled)

        #expect(plan.days.map(\.dayIndex) == Array(0..<7))
    }

    @Test func recipesAreMatchedBySlotNotByPosition() throws {
        let skeleton = PlanSkeleton.week(productIDs: products.map(\.id))
        // Same recipes, but returned dinner-first.
        let reversedRecipes = Dictionary(uniqueKeysWithValues: skeleton.days.map { day in
            (day.dayIndex, DayRecipes(meals: DayRecipes.covering(day).meals.reversed()))
        })

        let plan = try assemble(skeleton, recipes: reversedRecipes)

        for day in plan.days {
            for meal in day.meals {
                #expect(meal.name.contains(meal.slot.rawValue))
            }
        }
    }

    @Test func aMealWithNoRecipeIsAnError() {
        let skeleton = PlanSkeleton.week(productIDs: products.map(\.id))
        // Day 3 gets recipes for breakfast only.
        let partial = Dictionary(uniqueKeysWithValues: skeleton.days.map { day -> (Int, DayRecipes) in
            guard day.dayIndex == 3 else { return (day.dayIndex, DayRecipes.covering(day)) }
            let breakfastOnly = DayRecipes(meals: DayRecipes.covering(day).meals.filter { $0.slot == .breakfast })
            return (day.dayIndex, breakfastOnly)
        })

        #expect(throws: GenerationError.missingRecipe(day: 3, slot: .lunch)) {
            try assemble(skeleton, recipes: partial)
        }
    }

    @Test func anEmptyStepListCountsAsAMissingRecipe() {
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 100),
            .init(productID: "p1", grams: 100),
        ])
        let stepless = [0: DayRecipes(meals: [
            .init(slot: .breakfast, mealName: "Nothing", ingredientLines: ["a"], steps: [])
        ])]

        #expect(throws: GenerationError.missingRecipe(day: 0, slot: .breakfast)) {
            try assemble(skeleton, recipes: stepless)
        }
    }

    // MARK: - Cost attribution

    @Test func costSharesAcrossAProductSumToItsPackageCost() throws {
        let plan = try assemble(PlanSkeleton.week(productIDs: products.map(\.id)))

        let sharesByProduct = Dictionary(
            grouping: plan.days.flatMap { $0.meals.flatMap(\.ingredients) },
            by: \.productID
        ).mapValues { $0.reduce(Decimal(0)) { $0 + $1.costShare } }

        for line in plan.shoppingList {
            let attributed = try #require(sharesByProduct[line.productID])
            let difference = abs(NSDecimalNumber(decimal: attributed - line.cost).doubleValue)
            #expect(difference < 0.01)
        }
    }

    @Test func mealCostsSumToTheBasketTotal() throws {
        let plan = try assemble(PlanSkeleton.week(productIDs: products.map(\.id)))

        let mealTotal = plan.days
            .flatMap(\.meals)
            .reduce(Decimal(0)) { $0 + $1.estimatedCost }

        let difference = abs(NSDecimalNumber(decimal: mealTotal - plan.totalCost).doubleValue)
        #expect(difference < 0.01)
    }

    @Test func aProductUsedTwiceAsMuchInOneMealCarriesTwiceTheCost() throws {
        let product = Product.fixture(id: "solo", price: 6, grams: 1000)
        let partner = Product.fixture(id: "partner", price: 1, grams: 1000)
        let skeleton = PlanSkeleton(days: [
            .init(dayIndex: 0, meals: [
                .init(slot: .breakfast, name: "b", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "solo", grams: 100), .init(productID: "partner", grams: 10)],
                      pantryItems: []),
                .init(slot: .lunch, name: "l", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "solo", grams: 200), .init(productID: "partner", grams: 10)],
                      pantryItems: []),
                .init(slot: .dinner, name: "d", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "partner", grams: 10), .init(productID: "solo", grams: 100)],
                      pantryItems: []),
            ])
        ])

        let plan = try assemble(skeleton, products: [product, partner])

        let soloShares = plan.days[0].meals.map { meal in
            meal.ingredients.first { $0.productID == "solo" }?.costShare ?? 0
        }

        // Lunch uses 200 g against breakfast's 100 g.
        #expect(soloShares[1] == soloShares[0] * 2)
    }

    // MARK: - Snapshots and pantry

    @Test func productNamesAreSnapshottedIntoTheIngredient() throws {
        let plan = try assemble(PlanSkeleton.week(productIDs: products.map(\.id)))

        let names = Set(plan.days.flatMap { $0.meals.flatMap { $0.ingredients.map(\.productName) } })
        #expect(names.contains("Test p0"))
    }

    @Test func quantitiesCarryTheProductsOwnUnit() throws {
        let liquid = Product(
            id: "milk",
            name: "Oat drink",
            departmentID: "bevande",
            categoryID: "en:plant-based-beverages",
            baseQuantity: .volume(milliliters: 1000),
            price: 2,
            nutrition: NutritionFacts(
                energyKcal: 50, proteins: 1, carbohydrates: 6, sugars: 3,
                fat: 1, saturatedFat: 0, fiber: 0, salt: 0.1
            ),
            labelIDs: [],
            allergenIDs: []
        )
        let solid = Product.fixture(id: "oats")
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "milk", grams: 200),
            .init(productID: "oats", grams: 60),
        ])

        let plan = try assemble(skeleton, products: [liquid, solid])
        let ingredients = plan.days[0].meals[0].ingredients

        #expect(ingredients.first { $0.productID == "milk" }?.unit == "ml")
        #expect(ingredients.first { $0.productID == "oats" }?.unit == "g")
    }

    @Test func pantryStaplesAreParsedAndKeptSeparateFromPricedIngredients() throws {
        let plan = try assemble(PlanSkeleton.week(productIDs: products.map(\.id)))
        let meal = plan.days[0].meals[0]

        #expect(meal.pantryItems == [.salt])
        #expect(!meal.ingredients.contains { $0.productID == PantryStaple.salt.rawValue })
    }
}
