//
//  PlanSkeletonPromptBuilderTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct PlanSkeletonPromptBuilderTests {

    @Test func userPromptListsEveryCandidateProductID() {
        let products = [Product.stub(id: "p1"), Product.stub(id: "p2"), Product.stub(id: "p3")]
        let request = PlanSkeletonRequest(dayCount: 1, configuration: .stub(), candidates: products)

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        for product in products {
            #expect(prompt.contains(product.id))
        }
    }

    @Test func userPromptStatesWholePackageCosting() {
        let request = PlanSkeletonRequest(dayCount: 7, configuration: .stub(), candidates: [Product.stub(id: "p1")])

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        #expect(prompt.contains("full package price"))
    }

    @Test func userPromptIncludesPerSlotExpectations() {
        let request = PlanSkeletonRequest(dayCount: 7, configuration: .stub(), candidates: [Product.stub(id: "p1")])

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        #expect(prompt.contains("breakfast"))
        #expect(prompt.contains("10 minutes"))
        #expect(prompt.contains("45 minutes"))
    }

    @Test func skuBudgetScalesWithDayCount() {
        let oneDay = PlanSkeletonRequest(dayCount: 1, configuration: .stub(), candidates: [Product.stub(id: "p1")])
        let fullWeek = PlanSkeletonRequest(dayCount: 7, configuration: .stub(), candidates: [Product.stub(id: "p1")])

        let oneDayPrompt = PlanSkeletonPromptBuilder.userPrompt(for: oneDay)
        let fullWeekPrompt = PlanSkeletonPromptBuilder.userPrompt(for: fullWeek)

        #expect(fullWeekPrompt.contains("at most 28 distinct products"))
        #expect(oneDayPrompt.contains("at most 6 distinct products"))
    }

    @Test func userPromptMentionsActiveDietaryNeedsAndGoalsWhenPresent() {
        let configuration = MealPlanConfiguration.stub(dietaryNeeds: [.vegan], goals: [.highProtein])
        let request = PlanSkeletonRequest(dayCount: 7, configuration: configuration, candidates: [Product.stub(id: "p1")])

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        #expect(prompt.contains("vegan"))
        #expect(prompt.contains("highProtein"))
    }

    @Test func userPromptOmitsDietaryAndGoalLinesWhenNoneActive() {
        let request = PlanSkeletonRequest(dayCount: 7, configuration: .stub(), candidates: [Product.stub(id: "p1")])

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        #expect(!prompt.contains("Active dietary needs"))
        #expect(!prompt.contains("Active nutritional goals"))
    }

    @Test func userPromptOnlyAllowsRealPantryStapleValues() {
        let request = PlanSkeletonRequest(dayCount: 7, configuration: .stub(), candidates: [Product.stub(id: "p1")])

        let prompt = PlanSkeletonPromptBuilder.userPrompt(for: request)

        for staple in PantryStaple.allCases {
            #expect(prompt.contains(staple.rawValue))
        }
    }

    @Test func systemPromptForbidsBudgetArithmeticByTheModel() {
        #expect(PlanSkeletonPromptBuilder.systemPrompt().contains("never perform budget arithmetic"))
    }
}

private extension Product {
    static func stub(id: String) -> Product {
        Product(
            id: id,
            name: "Test \(id)",
            departmentID: "dispensa",
            categoryID: "en:test-category",
            baseQuantity: .mass(grams: 500),
            price: Decimal(1.99),
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
            createdAt: Date()
        )
    }
}
