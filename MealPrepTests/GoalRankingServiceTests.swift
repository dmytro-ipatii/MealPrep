//
//  GoalRankingServiceTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct GoalRankingServiceTests {

    @Test func highProteinRanksHigherProteinAboveLowerProteinInSameCategory() {
        let highProtein = Product.stub(id: "high", categoryID: "en:cheeses", proteins: 25)
        let lowProtein = Product.stub(id: "low", categoryID: "en:cheeses", proteins: 2)

        let scores = GoalRankingService.score([highProtein, lowProtein], for: [.highProtein])

        #expect(scores["high"]! > scores["low"]!)
    }

    @Test func lowSugarRanksLowerSugarAboveHigherSugarInSameCategory() {
        let lowSugar = Product.stub(id: "low", categoryID: "en:jams", sugars: 5)
        let highSugar = Product.stub(id: "high", categoryID: "en:jams", sugars: 60)

        let scores = GoalRankingService.score([lowSugar, highSugar], for: [.lowSugar])

        #expect(scores["low"]! > scores["high"]!)
    }

    @Test func lowFatCombinesFatAndSaturatedFat() {
        let lowFat = Product.stub(id: "low", categoryID: "en:meats", fat: 2, saturatedFat: 0.5)
        let highFat = Product.stub(id: "high", categoryID: "en:meats", fat: 30, saturatedFat: 12)

        let scores = GoalRankingService.score([lowFat, highFat], for: [.lowFat])

        #expect(scores["low"]! > scores["high"]!)
    }

    @Test func normalizationIsScopedPerCategory() {
        // "high" has more protein than every yoghurt but less than the meat,
        // yet it should win its own category comparison.
        let cheapYoghurtA = Product.stub(id: "yA", categoryID: "en:yogurts", proteins: 3)
        let cheapYoghurtB = Product.stub(id: "yB", categoryID: "en:yogurts", proteins: 5)
        let meat = Product.stub(id: "meat", categoryID: "en:meats", proteins: 25)

        let scores = GoalRankingService.score([cheapYoghurtA, cheapYoghurtB, meat], for: [.highProtein])

        #expect(scores["yB"]! > scores["yA"]!)
        // The single meat product is the only one in its category, so with no
        // spread to normalize against it falls back to the neutral midpoint.
        #expect(scores["meat"] == 0.5)
    }

    @Test func multipleActiveGoalsAverageTheirSignals() {
        let balanced = Product.stub(id: "balanced", categoryID: "en:snacks", proteins: 15, sugars: 10)
        let sugaryOnly = Product.stub(id: "sugary", categoryID: "en:snacks", proteins: 15, sugars: 40)

        let scores = GoalRankingService.score([balanced, sugaryOnly], for: [.highProtein, .lowSugar])

        #expect(scores["balanced"]! > scores["sugary"]!)
    }

    @Test func allScoresAreWithinUnitRange() {
        let products = (0..<10).map { Product.stub(id: "p\($0)", categoryID: "en:snacks", proteins: Double($0) * 3) }

        let scores = GoalRankingService.score(products, for: [.highProtein, .lowSugar, .lowFat, .lowCarbs, .lowSalt])

        #expect(scores.values.allSatisfy { $0 >= 0 && $0 <= 1 })
    }

    @Test func emptyGoalsStillYieldsPackageEfficiencySignal() {
        // Same category, same price, but one package feeds far more portions.
        let bulkValue = Product.stub(id: "bulk", categoryID: "en:rices", grams: 5000, price: 4)
        let tinyExpensive = Product.stub(id: "tiny", categoryID: "en:rices", grams: 150, price: 4)

        let scores = GoalRankingService.score([bulkValue, tinyExpensive], for: [])

        #expect(scores["bulk"]! > scores["tiny"]!)
    }
}

private extension Product {
    static func stub(
        id: String,
        categoryID: String,
        departmentID: String = "dispensa",
        grams: Double = 500,
        price: Double = 1.99,
        proteins: Double = 5,
        sugars: Double = 2,
        fat: Double = 3,
        saturatedFat: Double = 1
    ) -> Product {
        Product(
            id: id,
            name: "Test Product \(id)",
            departmentID: departmentID,
            categoryID: categoryID,
            baseQuantity: .mass(grams: grams),
            price: Decimal(price),
            nutrition: NutritionFacts(
                energyKcal: 100, proteins: proteins, carbohydrates: 10, sugars: sugars,
                fat: fat, saturatedFat: saturatedFat, fiber: 1, salt: 0.5
            ),
            labelIDs: [],
            allergenIDs: []
        )
    }
}
