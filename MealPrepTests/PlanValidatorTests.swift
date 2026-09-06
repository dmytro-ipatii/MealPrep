//
//  PlanValidatorTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct PlanValidatorTests {

    private let products = (0..<6).map { Product.fixture(id: "p\($0)") }

    private func validate(
        _ skeleton: PlanSkeleton,
        products: [Product]? = nil,
        configuration: MealPlanConfiguration = .fixture(),
        expectedDayCount: Int = MealPlanGenerator.daysPerPlan,
        skuLimit: Int = 28
    ) -> [PlanViolation] {
        PlanValidator.validate(
            skeleton,
            candidates: products ?? self.products,
            configuration: configuration,
            expectedDayCount: expectedDayCount,
            skuLimit: skuLimit
        )
    }

    // MARK: - Happy path

    @Test func aStructurallyCompleteAffordableWeekHasNoViolations() {
        let skeleton = PlanSkeleton.week(productIDs: products.map(\.id))

        #expect(validate(skeleton).isEmpty)
    }

    // MARK: - Product identity and safety

    @Test func productNotInTheCandidateListIsReported() {
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 100),
            .init(productID: "hallucinated", grams: 100),
        ])

        let violations = validate(skeleton, expectedDayCount: 1)

        #expect(violations.contains(.unknownProduct(id: "hallucinated", day: 0, slot: .breakfast)))
    }

    @Test func dietaryViolationIsCaughtAsABackstopEvenThoughFilteringRanEarlier() {
        // A product that should never have reached the candidate list. The
        // validator must not trust that the earlier filter did its job.
        let unsafe = Product.fixture(id: "cheese", categoryID: "en:cheeses", allergenIDs: ["en:milk"])
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 100),
            .init(productID: "cheese", grams: 100),
        ])

        let violations = validate(
            skeleton,
            products: products + [unsafe],
            configuration: .fixture(dietaryNeeds: [.dairyFree]),
            expectedDayCount: 1
        )

        #expect(violations.contains(.dietaryViolation(productID: "cheese", need: .dairyFree)))
    }

    @Test func eachOffendingProductIsReportedOnceNotOncePerMeal() {
        let unsafe = Product.fixture(id: "cheese", categoryID: "en:cheeses", allergenIDs: ["en:milk"])
        let skeleton = PlanSkeleton.week(productIDs: ["p0", "cheese"])

        let violations = validate(
            skeleton,
            products: products + [unsafe],
            configuration: .fixture(dietaryNeeds: [.dairyFree])
        )

        let dairyViolations = violations.filter {
            $0 == .dietaryViolation(productID: "cheese", need: .dairyFree)
        }
        #expect(dairyViolations.count == 1)
    }

    // MARK: - Pantry rules

    @Test func pantryItemOutsideTheEnumIsReported() {
        let skeleton = PlanSkeleton.singleMeal(
            ingredients: [.init(productID: "p0", grams: 100), .init(productID: "p1", grams: 100)],
            pantryItems: ["truffleOil"]
        )

        let violations = validate(skeleton, expectedDayCount: 1)

        #expect(violations.contains(.pantryItemNotRecognized("truffleOil")))
    }

    @Test func buyingSomethingTheUserAlreadyOwnsIsReported() {
        let oliveOil = Product.fixture(id: "oil", categoryID: "en:olive-oils", price: 4)
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 100),
            .init(productID: "oil", grams: 20),
        ])

        let violations = validate(skeleton, products: products + [oliveOil], expectedDayCount: 1)

        #expect(violations.contains(.stapleDuplicatedAsIngredient(productID: "oil")))
    }

    // MARK: - Quantities

    @Test func implausibleQuantitiesAreReported() {
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 0),
            .init(productID: "p1", grams: 5000),
        ])

        let violations = validate(skeleton, expectedDayCount: 1)

        #expect(violations.contains(.implausibleQuantity(productID: "p0", grams: 0)))
        #expect(violations.contains(.implausibleQuantity(productID: "p1", grams: 5000)))
    }

    // MARK: - Cost

    @Test func overBudgetIsReportedWithTheComputedTotal() {
        let expensive = (0..<6).map { Product.fixture(id: "e\($0)", price: 20) }
        let skeleton = PlanSkeleton.week(productIDs: expensive.map(\.id))

        let violations = validate(skeleton, products: expensive, configuration: .fixture(weeklyBudget: 10))

        let overBudget = violations.compactMap { violation -> (Decimal, Decimal)? in
            guard case .overBudget(let computed, let limit) = violation else { return nil }
            return (computed, limit)
        }

        #expect(overBudget.count == 1)
        #expect(overBudget.first?.1 == 10)
        #expect((overBudget.first?.0 ?? 0) > 10)
    }

    @Test func skuCountExceededIsReported() {
        let many = (0..<12).map { Product.fixture(id: "m\($0)") }
        let skeleton = PlanSkeleton.week(productIDs: many.map(\.id))

        let violations = validate(skeleton, products: many, skuLimit: 5)

        #expect(violations.contains(.skuCountExceeded(count: 12, limit: 5)))
    }

    // MARK: - Structure

    @Test func missingDayIsReported() {
        let skeleton = PlanSkeleton.week(productIDs: products.map(\.id), dayCount: 5)

        let violations = validate(skeleton)

        #expect(violations.contains(.missingDay(dayIndex: 5)))
        #expect(violations.contains(.missingDay(dayIndex: 6)))
    }

    @Test func missingMealIsReported() {
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "p0", grams: 100),
            .init(productID: "p1", grams: 100),
        ])

        let violations = validate(skeleton, expectedDayCount: 1)

        #expect(violations.contains(.missingMeal(day: 0, slot: .lunch)))
        #expect(violations.contains(.missingMeal(day: 0, slot: .dinner)))
    }

    @Test func aMealWithASingleIngredientIsReported() {
        let skeleton = PlanSkeleton.singleMeal(ingredients: [.init(productID: "p0", grams: 100)])

        let violations = validate(skeleton, expectedDayCount: 1)

        #expect(violations.contains(.tooFewIngredients(day: 0, slot: .breakfast, count: 1)))
    }

    // MARK: - Nutritional goals

    @Test func aMissedGoalIsReportedButIsAdvisoryNotBlocking() {
        let lowProtein = (0..<6).map { Product.fixture(id: "lp\($0)", proteins: 0.5) }
        let skeleton = PlanSkeleton.week(productIDs: lowProtein.map(\.id))

        let violations = validate(
            skeleton,
            products: lowProtein,
            configuration: .fixture(goals: [.highProtein])
        )

        let goalViolations = violations.filter { violation in
            guard case .goalMissed = violation else { return false }
            return true
        }
        let allAdvisory = goalViolations.allSatisfy { !$0.isBlocking }
        let hasBlocking = violations.contains(where: \.isBlocking)

        #expect(!goalViolations.isEmpty)
        #expect(allAdvisory)
        #expect(!hasBlocking)
    }

    @Test func aMetGoalProducesNoGoalViolation() {
        // 6 ingredients per day × 100 g × 30 g protein per 100 g = 180 g/day.
        let highProtein = (0..<6).map { Product.fixture(id: "hp\($0)", proteins: 30) }
        let skeleton = PlanSkeleton.week(productIDs: highProtein.map(\.id))

        let violations = validate(
            skeleton,
            products: highProtein,
            configuration: .fixture(goals: [.highProtein])
        )

        let hasGoalViolation = violations.contains { violation in
            guard case .goalMissed = violation else { return false }
            return true
        }

        #expect(!hasGoalViolation)
    }

    @Test func goalsAreEvaluatedPerDayNotPerMeal() {
        // Only dinner carries protein; the day still clears the threshold, so
        // no violation should be raised for the protein-free breakfast.
        let lean = Product.fixture(id: "lean", proteins: 0)
        let rich = Product.fixture(id: "rich", proteins: 200)
        let skeleton = PlanSkeleton(days: [
            .init(dayIndex: 0, meals: [
                .init(slot: .breakfast, name: "b", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "lean", grams: 100), .init(productID: "lean", grams: 50)],
                      pantryItems: []),
                .init(slot: .lunch, name: "l", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "lean", grams: 100), .init(productID: "lean", grams: 50)],
                      pantryItems: []),
                .init(slot: .dinner, name: "d", prepTimeMinutes: 5,
                      ingredients: [.init(productID: "rich", grams: 100), .init(productID: "lean", grams: 50)],
                      pantryItems: []),
            ])
        ])

        let violations = validate(
            skeleton,
            products: [lean, rich],
            configuration: .fixture(goals: [.highProtein]),
            expectedDayCount: 1
        )

        let hasGoalViolation = violations.contains { violation in
            guard case .goalMissed = violation else { return false }
            return true
        }

        #expect(!hasGoalViolation)
    }
}
