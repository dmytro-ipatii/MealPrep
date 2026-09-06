//
//  DietaryFilterServiceTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import Testing
@testable import MealPrep

struct DietaryFilterServiceTests {

    // MARK: - Allergen exclusion (hard signal)

    @Test func dairyFreeExcludesMilkAllergen() {
        let product = Product.stub(departmentID: "ortofrutta", categoryID: "en:fruits", allergenIDs: ["en:milk"])
        #expect(!DietaryFilterService.isSafe(product, for: .dairyFree))
    }

    @Test func veganExcludesEggAllergenEvenOutsideDairyDepartment() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:sauces", allergenIDs: ["en:eggs"])
        #expect(!DietaryFilterService.isSafe(product, for: .vegan))
    }

    @Test func glutenFreeExcludesGlutenAllergen() {
        let product = Product.stub(departmentID: "ortofrutta", categoryID: "en:fruits", allergenIDs: ["en:gluten"])
        #expect(!DietaryFilterService.isSafe(product, for: .glutenFree))
    }

    // MARK: - Department / category exclusion

    @Test func dairyFreeExcludesDairyDepartmentEvenWithoutAllergenData() {
        let product = Product.stub(departmentID: "latticini", categoryID: "en:cheeses", allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .dairyFree))
    }

    @Test func vegetarianExcludesMeatCategory() {
        let product = Product.stub(departmentID: "carne", categoryID: "en:meats", allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .vegetarian))
    }

    @Test func pescatarianAllowsFishButExcludesMeat() {
        let fish = Product.stub(departmentID: "pesce", categoryID: "en:fishes", allergenIDs: ["en:fish"])
        let meat = Product.stub(departmentID: "carne", categoryID: "en:meats", allergenIDs: [])

        #expect(DietaryFilterService.isSafe(fish, for: .pescatarian))
        #expect(!DietaryFilterService.isSafe(meat, for: .pescatarian))
    }

    @Test func vegetarianExcludesFishAllergenEvenIfNotInFishDepartment() {
        let product = Product.stub(departmentID: "conserve", categoryID: "en:canned-fishes", allergenIDs: ["en:fish"])
        #expect(!DietaryFilterService.isSafe(product, for: .vegetarian))
    }

    // MARK: - Missing label in a risky category is excluded (per plan section 6)

    @Test func dairyFreeExcludesUnlabelledRiskyCategory() {
        let product = Product.stub(departmentID: "panetteria", categoryID: "en:cakes", labelIDs: [], allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .dairyFree))
    }

    @Test func dairyFreeAllowsRiskyCategoryLabelledVegan() {
        let product = Product.stub(departmentID: "panetteria", categoryID: "en:cakes", labelIDs: ["en:vegan"], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .dairyFree))
    }

    @Test func veganExcludesUnlabelledRiskyCategory() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:sauces", labelIDs: [], allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .vegan))
    }

    @Test func veganAllowsRiskyCategoryLabelledVegan() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:sauces", labelIDs: ["en:vegan"], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .vegan))
    }

    @Test func vegetarianExcludesUnlabelledRiskyCategory() {
        let product = Product.stub(departmentID: "surgelati", categoryID: "en:frozen-pizzas", labelIDs: [], allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .vegetarian))
    }

    @Test func vegetarianAllowsRiskyCategoryLabelledVegetarian() {
        let product = Product.stub(departmentID: "surgelati", categoryID: "en:frozen-pizzas", labelIDs: ["en:vegetarian"], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .vegetarian))
    }

    @Test func pescatarianExcludesUnlabelledRiskyCategory() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:soups", labelIDs: [], allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .pescatarian))
    }

    @Test func pescatarianAllowsRiskyCategoryLabelledVegan() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:soups", labelIDs: ["en:vegan"], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .pescatarian))
    }

    @Test func glutenFreeExcludesUnlabelledRiskyCategory() {
        // No "en:gluten-free" label exists anywhere in the catalog, so this
        // stays excluded even when labelled with something else.
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:sauces", labelIDs: ["en:vegan"], allergenIDs: [])
        #expect(!DietaryFilterService.isSafe(product, for: .glutenFree))
    }

    @Test func glutenFreeAllowsRiskyCategoryLabelledGlutenFree() {
        let product = Product.stub(departmentID: "dispensa", categoryID: "en:sauces", labelIDs: ["en:gluten-free"], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .glutenFree))
    }

    // MARK: - Inherently safe categories need no label

    @Test func veganAllowsUnlabelledPlainProduce() {
        let product = Product.stub(departmentID: "ortofrutta", categoryID: "en:vegetables", labelIDs: [], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .vegan))
    }

    @Test func glutenFreeAllowsUnlabelledRice() {
        let product = Product.stub(departmentID: "pasta-riso", categoryID: "en:rices", labelIDs: [], allergenIDs: [])
        #expect(DietaryFilterService.isSafe(product, for: .glutenFree))
    }

    // MARK: - Composition (intersection)

    @Test func multipleActiveNeedsComposeAsIntersection() {
        // Vegan-labelled cheese: satisfies dairyFree's label rescue in a risky
        // category, but cheese is hard-forbidden for vegan regardless of label.
        let product = Product.stub(departmentID: "latticini", categoryID: "en:cheeses", labelIDs: ["en:vegan"], allergenIDs: [])

        let filtered = DietaryFilterService.filter([product], for: [.dairyFree, .vegan])

        #expect(filtered.isEmpty)
    }

    @Test func filterWithNoActiveNeedsReturnsAllProducts() {
        let products = [
            Product.stub(departmentID: "carne", categoryID: "en:meats", allergenIDs: []),
            Product.stub(departmentID: "latticini", categoryID: "en:cheeses", allergenIDs: ["en:milk"]),
        ]

        #expect(DietaryFilterService.filter(products, for: []).count == products.count)
    }

    // MARK: - Real catalog sanity

    @Test func noDairyFreeResultFromRealCatalogContainsMilkAllergen() throws {
        let result = try ProductCatalogLoader.load()
        let filtered = DietaryFilterService.filter(result.products, for: [.dairyFree])

        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { !$0.allergenIDs.contains("en:milk") })
    }

    @Test func noVeganResultFromRealCatalogIsInMeatOrDairyDepartment() throws {
        let result = try ProductCatalogLoader.load()
        let filtered = DietaryFilterService.filter(result.products, for: [.vegan])

        #expect(!filtered.isEmpty)
        #expect(filtered.allSatisfy { !["carne", "salumi", "pesce", "latticini"].contains($0.departmentID) })
    }
}

private extension Product {
    static func stub(
        id: String = "1",
        name: String = "Test Product",
        departmentID: String,
        categoryID: String,
        labelIDs: Set<String> = [],
        allergenIDs: Set<String> = []
    ) -> Product {
        Product(
            id: id,
            name: name,
            departmentID: departmentID,
            categoryID: categoryID,
            baseQuantity: .mass(grams: 500),
            price: Decimal(1.99),
            nutrition: NutritionFacts(
                energyKcal: 100, proteins: 5, carbohydrates: 10, sugars: 2,
                fat: 3, saturatedFat: 1, fiber: 1, salt: 0.5
            ),
            labelIDs: labelIDs,
            allergenIDs: allergenIDs
        )
    }
}
