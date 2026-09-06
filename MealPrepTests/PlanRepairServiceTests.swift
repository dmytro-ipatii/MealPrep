//
//  PlanRepairServiceTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct PlanRepairServiceTests {

    // MARK: - Individual strategies

    @Test func consolidateReplacesASingleUseProductWithOneAlreadyInTheBasket() {
        let staple = Product.fixture(id: "staple", categoryID: "en:pastas", price: 1)
        let oneOff = Product.fixture(id: "oneOff", categoryID: "en:pastas", price: 9)
        let filler = Product.fixture(id: "filler", categoryID: "en:legumes", price: 1)

        // "staple" appears in several meals, "oneOff" in exactly one.
        let skeleton = PlanSkeleton
            .week(productIDs: ["staple", "filler"])
            .replacingFirstIngredient(with: "oneOff")

        let repaired = PlanRepairService.consolidate(
            skeleton,
            productsByID: lookup([staple, oneOff, filler]),
            candidates: [staple, oneOff, filler],
            skuLimit: 28
        )

        let result = try! #require(repaired)
        #expect(!result.distinctProductIDs.contains("oneOff"))
        #expect(result.distinctProductIDs.contains("staple"))
    }

    @Test func consolidateMergesTwoIngredientsOntoOneAndSumsTheQuantities() {
        let a = Product.fixture(id: "a", categoryID: "en:pastas", price: 1)
        let b = Product.fixture(id: "b", categoryID: "en:pastas", price: 5)
        let c = Product.fixture(id: "c", categoryID: "en:legumes", price: 1)

        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "a", grams: 100),
            .init(productID: "b", grams: 50),
            .init(productID: "c", grams: 100),
        ])

        let repaired = PlanRepairService.consolidate(
            skeleton,
            productsByID: lookup([a, b, c]),
            candidates: [a, b, c],
            skuLimit: 28
        )

        let meal = try! #require(repaired?.days.first?.meals.first)
        #expect(meal.ingredients.count == 2)

        let merged = try! #require(meal.ingredients.first { $0.productID == "a" })
        #expect(merged.grams == 150)
        #expect(!meal.ingredients.contains { $0.productID == "b" })
    }

    @Test func consolidateDeclinesWhenTheMergeWouldEmptyOutAMeal() {
        // Both products are in the same two-ingredient meal, so merging them
        // would leave that meal with a single ingredient. Trading a cost
        // violation for a structural one is not a repair.
        let a = Product.fixture(id: "a", categoryID: "en:pastas", price: 1)
        let b = Product.fixture(id: "b", categoryID: "en:pastas", price: 5)

        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "a", grams: 100),
            .init(productID: "b", grams: 50),
        ])

        let repaired = PlanRepairService.consolidate(
            skeleton,
            productsByID: lookup([a, b]),
            candidates: [a, b],
            skuLimit: 28
        )

        #expect(repaired == nil)
    }

    @Test func substitutePicksACheaperProductInTheSameCategory() {
        let expensive = Product.fixture(id: "expensive", categoryID: "en:cheeses", price: 9)
        let cheap = Product.fixture(id: "cheap", categoryID: "en:cheeses", price: 2)
        let other = Product.fixture(id: "other", categoryID: "en:legumes", price: 1)

        let skeleton = PlanSkeleton.week(productIDs: ["expensive", "other"])

        let repaired = PlanRepairService.substitute(
            skeleton,
            productsByID: lookup([expensive, cheap, other]),
            candidates: [expensive, cheap, other],
            skuLimit: 28
        )

        let result = try! #require(repaired)
        #expect(result.distinctProductIDs.contains("cheap"))
        #expect(!result.distinctProductIDs.contains("expensive"))
    }

    @Test func substituteNeverSwapsAcrossCategories() {
        let meat = Product.fixture(id: "meat", categoryID: "en:meats", price: 9)
        let cheapVegetable = Product.fixture(id: "veg", categoryID: "en:vegetables", price: 1)

        let skeleton = PlanSkeleton.week(productIDs: ["meat", "veg"])

        let repaired = PlanRepairService.substitute(
            skeleton,
            productsByID: lookup([meat, cheapVegetable]),
            candidates: [meat, cheapVegetable],
            skuLimit: 28
        )

        // No cheaper meat exists, so there is no legitimate move.
        #expect(repaired == nil)
    }

    @Test func resizeShrinksOnlyWhenItDropsAWholePackage() {
        // 21 meals × 55 g = 1155 g of a 1000 g package → 2 packages. Scaling
        // to 1000 g total drops one package and costs each meal only ~13%.
        let product = Product.fixture(id: "bulk", price: 5, grams: 1000)
        let partner = Product.fixture(id: "partner", categoryID: "en:legumes", price: 1, grams: 5000)
        let skeleton = PlanSkeleton.week(productIDs: ["bulk", "partner"], grams: 55)

        let repaired = PlanRepairService.resize(
            skeleton,
            productsByID: lookup([product, partner]),
            candidates: [product, partner],
            skuLimit: 28
        )

        let result = try! #require(repaired)
        let usages = PlanValidator.usages(in: result, productsByID: lookup([product, partner]))
        let basket = CostCalculator.basket(for: usages)
        let bulkLine = try! #require(basket.lines.first { $0.product.id == "bulk" })

        #expect(bulkLine.packages == 1)
    }

    @Test func resizeDeclinesWhenTheShrinkWouldBeTooSevere() {
        // 21 × 80 g = 1680 g of a 1000 g package → 2 packages. Getting down to
        // one package means a 40% cut to every portion, which is no longer the
        // plan the model designed — resize must decline and leave it to another
        // strategy.
        let product = Product.fixture(id: "bulk", price: 5, grams: 1000)
        let partner = Product.fixture(id: "partner", categoryID: "en:legumes", price: 1, grams: 5000)
        let skeleton = PlanSkeleton.week(productIDs: ["bulk", "partner"], grams: 80)

        let repaired = PlanRepairService.resize(
            skeleton,
            productsByID: lookup([product, partner]),
            candidates: [product, partner],
            skuLimit: 28
        )

        #expect(repaired == nil)
    }

    @Test func simplifyDropsAnIngredientButNeverBelowTwoPerMeal() {
        let keep = Product.fixture(id: "keep", price: 1)
        let alsoKeep = Product.fixture(id: "alsoKeep", price: 1)
        let luxury = Product.fixture(id: "luxury", categoryID: "en:luxury", price: 30)

        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "keep", grams: 100),
            .init(productID: "alsoKeep", grams: 100),
            .init(productID: "luxury", grams: 100),
        ])

        let repaired = PlanRepairService.simplify(
            skeleton,
            productsByID: lookup([keep, alsoKeep, luxury]),
            candidates: [keep, alsoKeep, luxury],
            skuLimit: 28
        )

        let meal = try! #require(repaired?.days.first?.meals.first)
        #expect(meal.ingredients.count == 2)
        #expect(!meal.ingredients.contains { $0.productID == "luxury" })
    }

    @Test func simplifyDeclinesWhenEveryMealIsAlreadyMinimal() {
        let a = Product.fixture(id: "a")
        let b = Product.fixture(id: "b")
        let skeleton = PlanSkeleton.singleMeal(ingredients: [
            .init(productID: "a", grams: 100),
            .init(productID: "b", grams: 100),
        ])

        let repaired = PlanRepairService.simplify(
            skeleton,
            productsByID: lookup([a, b]),
            candidates: [a, b],
            skuLimit: 28
        )

        #expect(repaired == nil)
    }

    // MARK: - End to end

    @Test func repairBringsAnOverBudgetWeekIntoBudget() {
        // Six pricey products carry the whole week at €120; each has a €1
        // stand-in in the same category.
        let pricey = (0..<6).map {
            Product.fixture(id: "p\($0)", categoryID: "en:pastas", price: 20, grams: 5000)
        }
        let standIns = (0..<6).map {
            Product.fixture(id: "c\($0)", categoryID: "en:pastas", price: 1, grams: 5000)
        }
        let allCandidates = pricey + standIns

        let skeleton = PlanSkeleton.week(productIDs: pricey.map(\.id))
        let configuration = MealPlanConfiguration.fixture(weeklyBudget: 10)

        let before = CostCalculator.basket(
            for: PlanValidator.usages(in: skeleton, productsByID: lookup(allCandidates))
        )
        #expect(before.totalCost > configuration.weeklyBudget)

        let repaired = PlanRepairService.repair(
            skeleton,
            candidates: allCandidates,
            configuration: configuration,
            skuLimit: 28
        )

        let after = CostCalculator.basket(
            for: PlanValidator.usages(in: repaired, productsByID: lookup(allCandidates))
        )

        #expect(after.totalCost <= configuration.weeklyBudget)
    }

    @Test func repairNeverBreaksTheStructureOfTheWeek() {
        let pricey = (0..<6).map {
            Product.fixture(id: "p\($0)", categoryID: "en:pastas", price: 20, grams: 5000)
        }
        let standIns = (0..<6).map {
            Product.fixture(id: "c\($0)", categoryID: "en:pastas", price: 1, grams: 5000)
        }
        let allCandidates = pricey + standIns
        let configuration = MealPlanConfiguration.fixture(weeklyBudget: 10)

        let repaired = PlanRepairService.repair(
            PlanSkeleton.week(productIDs: pricey.map(\.id)),
            candidates: allCandidates,
            configuration: configuration,
            skuLimit: 28
        )

        let violations = PlanValidator.validate(
            repaired,
            candidates: allCandidates,
            configuration: configuration,
            expectedDayCount: 7,
            skuLimit: 28
        )
        let structural = violations.filter { violation in
            switch violation {
            case .missingDay, .missingMeal, .tooFewIngredients: true
            default: false
            }
        }

        #expect(repaired.days.count == 7)
        #expect(structural.isEmpty)
    }

    @Test func repairLeavesAnAlreadyValidPlanAlone() {
        let candidates = (0..<6).map { Product.fixture(id: "p\($0)") }
        let skeleton = PlanSkeleton.week(productIDs: candidates.map(\.id))

        let repaired = PlanRepairService.repair(
            skeleton,
            candidates: candidates,
            configuration: .fixture(),
            skuLimit: 28
        )

        #expect(repaired == skeleton)
    }

    // MARK: - Helpers

    private func lookup(_ products: [Product]) -> [String: Product] {
        Dictionary(products.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

}
