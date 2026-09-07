//
//  CostCalculatorTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct CostCalculatorTests {

    @Test func singleUsageBelowOnePackageStillCostsAFullPackage() {
        // 200 g needed from a 500 g package priced at €2 — one package, no
        // partial-package discount under whole-package costing.
        let rice = Product.stub(id: "rice", grams: 500, price: 2)

        let basket = CostCalculator.basket(for: [IngredientUsage(product: rice, quantity: 200)])

        let line = try! #require(basket.lines.first)
        #expect(line.packages == 1)
        #expect(line.purchasedQuantity == 500)
        #expect(line.cost == Decimal(2))
        #expect(line.wasteQuantity == 300)
        #expect(line.utilization == 0.4)
    }

    @Test func usageExceedingOnePackageRoundsUpToTwoPackages() {
        // 750 g needed from a 500 g package — must buy 2 packages (1000 g).
        let rice = Product.stub(id: "rice", grams: 500, price: 2)

        let basket = CostCalculator.basket(for: [IngredientUsage(product: rice, quantity: 750)])

        let line = try! #require(basket.lines.first)
        #expect(line.packages == 2)
        #expect(line.purchasedQuantity == 1000)
        #expect(line.cost == Decimal(4))
        #expect(line.wasteQuantity == 250)
    }

    @Test func exactPackageMultipleHasZeroWaste() {
        let rice = Product.stub(id: "rice", grams: 500, price: 2)

        let basket = CostCalculator.basket(for: [IngredientUsage(product: rice, quantity: 1000)])

        let line = try! #require(basket.lines.first)
        #expect(line.packages == 2)
        #expect(line.wasteQuantity == 0)
        #expect(line.utilization == 1)
    }

    @Test func usagesOfTheSameProductAcrossMealsAggregateBeforeCosting() {
        // Same product used in three different meals across the week: 100 g,
        // 150 g, 100 g — should be treated as one basket line of 350 g total,
        // not three separate package purchases.
        let flour = Product.stub(id: "flour", grams: 1000, price: 3)
        let usages = [
            IngredientUsage(product: flour, quantity: 100),
            IngredientUsage(product: flour, quantity: 150),
            IngredientUsage(product: flour, quantity: 100),
        ]

        let basket = CostCalculator.basket(for: usages)

        #expect(basket.lines.count == 1)
        let line = try! #require(basket.lines.first)
        #expect(line.requiredQuantity == 350)
        #expect(line.packages == 1)
        #expect(line.cost == Decimal(3))
    }

    @Test func distinctProductsProduceDistinctBasketLines() {
        let rice = Product.stub(id: "rice", grams: 500, price: 2)
        let pasta = Product.stub(id: "pasta", grams: 500, price: 1.5)

        let basket = CostCalculator.basket(for: [
            IngredientUsage(product: rice, quantity: 200),
            IngredientUsage(product: pasta, quantity: 300),
        ])

        #expect(basket.lines.count == 2)
        #expect(basket.totalCost == Decimal(2) + Decimal(1.5))
        #expect(basket.skuCount == 2)
    }

    @Test func totalWasteQuantitySumsAcrossLines() {
        let rice = Product.stub(id: "rice", grams: 500, price: 2)
        let pasta = Product.stub(id: "pasta", grams: 500, price: 1.5)

        let basket = CostCalculator.basket(for: [
            IngredientUsage(product: rice, quantity: 400),  // waste 100
            IngredientUsage(product: pasta, quantity: 300), // waste 200
        ])

        #expect(basket.totalWasteQuantity == 300)
    }

    @Test func volumeBasedProductsAreHandledLikeMassBasedOnes() {
        let milk = Product.stub(id: "milk", baseQuantity: .volume(milliliters: 1000), price: 1.2)

        let basket = CostCalculator.basket(for: [IngredientUsage(product: milk, quantity: 300)])

        let line = try! #require(basket.lines.first)
        #expect(line.packages == 1)
        #expect(line.purchasedQuantity == 1000)
        #expect(line.wasteQuantity == 700)
    }

    @Test func countBasedProductsUseItemCountAsPackageSize() {
        let eggs = Product.stub(id: "eggs", baseQuantity: .count(6), price: 2.5)

        let basket = CostCalculator.basket(for: [IngredientUsage(product: eggs, quantity: 8)])

        let line = try! #require(basket.lines.first)
        #expect(line.packages == 2)
        #expect(line.purchasedQuantity == 12)
        #expect(line.cost == Decimal(5))
    }

    @Test func emptyUsagesProduceAnEmptyBasket() {
        let basket = CostCalculator.basket(for: [])
        #expect(basket.lines.isEmpty)
        #expect(basket.totalCost == 0)
    }
}

private extension Product {
    static func stub(
        id: String,
        baseQuantity: BaseQuantity,
        price: Double
    ) -> Product {
        Product(
            id: id,
            name: "Test \(id)",
            departmentID: "dispensa",
            categoryID: "en:test-category",
            baseQuantity: baseQuantity,
            price: Decimal(price),
            nutrition: NutritionFacts(
                energyKcal: 100, proteins: 5, carbohydrates: 10, sugars: 2,
                fat: 3, saturatedFat: 1, fiber: 1, salt: 0.5
            ),
            labelIDs: [],
            allergenIDs: []
        )
    }

    static func stub(id: String, grams: Double, price: Double) -> Product {
        .stub(id: id, baseQuantity: .mass(grams: grams), price: price)
    }
}
