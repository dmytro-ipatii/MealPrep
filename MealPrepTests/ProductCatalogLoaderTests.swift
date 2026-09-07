//
//  ProductCatalogLoaderTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Testing
@testable import MealPrep

struct ProductCatalogLoaderTests {

    @Test func everyBundledRowEitherNormalizesOrIsFlagged() throws {
        let result = try ProductCatalogLoader.load()

        #expect(!result.products.isEmpty)
        #expect(result.skipped.allSatisfy { !$0.reason.isEmpty })

        let productIDs = Set(result.products.map(\.id))
        let skippedIDs = Set(result.skipped.map(\.id))
        #expect(productIDs.isDisjoint(with: skippedIDs))
    }

    @Test func normalizedProductsHaveNoZeroQuantity() throws {
        let result = try ProductCatalogLoader.load()

        for product in result.products {
            switch product.baseQuantity {
            case .mass(let grams): #expect(grams > 0)
            case .volume(let milliliters): #expect(milliliters > 0)
            case .count(let count): #expect(count > 0)
            }
        }
    }

    @Test func missingNetContentIsSkippedWithReason() {
        let dto = ProductDTO.stub(netContent: nil)

        let result = ProductCatalogLoader.normalize([dto])

        #expect(result.products.isEmpty)
        #expect(result.skipped.first?.reason == "missing netContent")
    }

    @Test func missingCategoryIsSkippedWithReason() {
        let dto = ProductDTO.stub(category: nil)

        let result = ProductCatalogLoader.normalize([dto])

        #expect(result.products.isEmpty)
        #expect(result.skipped.first?.reason == "missing category")
    }

    @Test func unrecognizedUnitIsSkippedWithReason() {
        let dto = ProductDTO.stub(netContent: NetContentDTO(value: 3, unit: "lbs"))

        let result = ProductCatalogLoader.normalize([dto])

        #expect(result.products.isEmpty)
        #expect(result.skipped.first?.reason == "unrecognized unit 'lbs'")
    }

    @Test func missingNutritionFieldsDefaultToZero() throws {
        let dto = ProductDTO.stub(
            nutrition: NutritionDTO(
                energyKcal100g: 100,
                proteins100g: nil,
                carbohydrates100g: nil,
                sugars100g: nil,
                fat100g: nil,
                saturatedFat100g: nil,
                fiber100g: nil,
                salt100g: nil
            )
        )

        let result = ProductCatalogLoader.normalize([dto])

        let product = try #require(result.products.first)
        #expect(product.nutrition.energyKcal == 100)
        #expect(product.nutrition.proteins == 0)
        #expect(product.nutrition.fiber == 0)
    }

    @Test func kilogramsAndLitersScaleToGramsAndMilliliters() {
        let kilogramProduct = ProductDTO.stub(netContent: NetContentDTO(value: 1.5, unit: "kg"))
        let literProduct = ProductDTO.stub(id: "2", netContent: NetContentDTO(value: 2, unit: "l"))

        let result = ProductCatalogLoader.normalize([kilogramProduct, literProduct])

        #expect(result.products.count == 2)
        #expect(result.products[0].baseQuantity == .mass(grams: 1500))
        #expect(result.products[1].baseQuantity == .volume(milliliters: 2000))
    }
}

private extension ProductDTO {
    static func stub(
        id: String = "1",
        category: TaxonomyRefDTO? = TaxonomyRefDTO(id: "en:test-category", name: "Test Category"),
        netContent: NetContentDTO? = NetContentDTO(value: 500, unit: "g"),
        nutrition: NutritionDTO = NutritionDTO(
            energyKcal100g: 100,
            proteins100g: 5,
            carbohydrates100g: 10,
            sugars100g: 2,
            fat100g: 3,
            saturatedFat100g: 1,
            fiber100g: 1,
            salt100g: 0.5
        )
    ) -> ProductDTO {
        ProductDTO(
            id: id,
            barcode: nil,
            name: "Test Product \(id)",
            brand: "Test Brand",
            department: TaxonomyRefDTO(id: "test-department", name: "Test Department"),
            category: category,
            quantity: nil,
            netContent: netContent,
            price: PriceDTO(amount: 1.99, currency: "EUR"),
            unitPrice: nil,
            nutrition: nutrition,
            nutriScore: nil,
            novaGroup: nil,
            labels: [],
            allergens: []
        )
    }
}
