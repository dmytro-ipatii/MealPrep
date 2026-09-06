//
//  FeasibilityCheckerTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct FeasibilityCheckerTests {

    @Test func minimumCostIsCheapestProductPerDepartmentSummed() {
        // dept A: cheapest is 1.50; dept B: cheapest is 3.00 -> floor 4.50.
        let products = [
            Product.stub(id: "a-cheap", departmentID: "a", price: 1.50),
            Product.stub(id: "a-expensive", departmentID: "a", price: 9.00),
            Product.stub(id: "b-cheap", departmentID: "b", price: 3.00),
            Product.stub(id: "b-expensive", departmentID: "b", price: 5.00),
        ]

        #expect(FeasibilityChecker.minimumWeeklyCost(for: products) == Decimal(4.50))
    }

    @Test func budgetAtExactlyTheFloorIsFeasible() {
        let products = [Product.stub(id: "a", departmentID: "a", price: 10)]
        let configuration = MealPlanConfiguration.stub(weeklyBudget: 10)

        let result = FeasibilityChecker.checkFeasibility(candidates: products, configuration: configuration)

        #expect(result == .feasible)
    }

    @Test func budgetBelowTheFloorIsInfeasibleWithTheComputedMinimum() {
        let products = [
            Product.stub(id: "a", departmentID: "a", price: 10),
            Product.stub(id: "b", departmentID: "b", price: 20),
        ]
        let configuration = MealPlanConfiguration.stub(weeklyBudget: 15)

        let result = FeasibilityChecker.checkFeasibility(candidates: products, configuration: configuration)

        guard case .infeasible(let minimumCost, let message) = result else {
            Issue.record("expected infeasible result")
            return
        }
        #expect(minimumCost == Decimal(30))
        #expect(message.contains("30"))
    }

    @Test func budgetAboveTheFloorIsFeasible() {
        let products = [Product.stub(id: "a", departmentID: "a", price: 10)]
        let configuration = MealPlanConfiguration.stub(weeklyBudget: 50)

        #expect(FeasibilityChecker.checkFeasibility(candidates: products, configuration: configuration) == .feasible)
    }

    @Test func messageNamesActiveDietaryNeedsAndGoals() {
        let products = [Product.stub(id: "a", departmentID: "a", price: 100)]
        let configuration = MealPlanConfiguration.stub(
            weeklyBudget: 5,
            dietaryNeeds: [.glutenFree],
            goals: [.highProtein]
        )

        guard case .infeasible(_, let message) = FeasibilityChecker.checkFeasibility(candidates: products, configuration: configuration) else {
            Issue.record("expected infeasible result")
            return
        }

        #expect(message.contains("gluten-free"))
        #expect(message.contains("high-protein"))
    }

    @Test func messageWithNoActiveConstraintsStaysGeneric() {
        let products = [Product.stub(id: "a", departmentID: "a", price: 100)]
        let configuration = MealPlanConfiguration.stub(weeklyBudget: 5)

        guard case .infeasible(_, let message) = FeasibilityChecker.checkFeasibility(candidates: products, configuration: configuration) else {
            Issue.record("expected infeasible result")
            return
        }

        #expect(!message.contains("A  week"))
        #expect(message.contains("This week"))
    }

    @Test func emptyCandidateListHasZeroFloorAndIsAlwaysFeasible() {
        let configuration = MealPlanConfiguration.stub(weeklyBudget: 0)

        #expect(FeasibilityChecker.minimumWeeklyCost(for: []) == 0)
        #expect(FeasibilityChecker.checkFeasibility(candidates: [], configuration: configuration) == .feasible)
    }
}

private extension Product {
    static func stub(id: String, departmentID: String, price: Double) -> Product {
        Product(
            id: id,
            name: "Test \(id)",
            departmentID: departmentID,
            categoryID: "en:test-category",
            baseQuantity: .mass(grams: 500),
            price: Decimal(price),
            nutrition: NutritionFacts(
                energyKcal: 100, proteins: 5, carbohydrates: 10, sugars: 2,
                fat: 3, saturatedFat: 1, fiber: 1, salt: 0.5
            ),
            labelIDs: [],
            allergenIDs: []
        )
    }
}

private extension MealPlanConfiguration {
    static func stub(
        weeklyBudget: Double,
        dietaryNeeds: Set<DietaryNeed> = [],
        goals: Set<NutritionalGoal> = []
    ) -> MealPlanConfiguration {
        MealPlanConfiguration(
            weeklyBudget: Decimal(weeklyBudget),
            currencyCode: "EUR",
            dietaryNeeds: dietaryNeeds,
            goals: goals,
            servings: 1,
            createdAt: Date()
        )
    }
}
