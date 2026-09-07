//
//  ProductCatalogLoader.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation

/// Loads the bundled product catalog and normalizes every row into a
/// `Product`. The catalog JSON shape must not leak past this loader.


enum ProductCatalogLoader: Sendable {

    nonisolated static func load(
        resourceName: String = "product_catalog_en",
        bundle: Bundle = .main
    ) throws -> ProductCatalogLoadResult {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw ProductCatalogLoadError.resourceNotFound
        }

        let data = try Data(contentsOf: url)

        let dtos: [ProductDTO]
        do {
            dtos = try JSONDecoder().decode([ProductDTO].self, from: data)
        } catch {
            throw ProductCatalogLoadError.decodingFailed(error)
        }

        return normalize(dtos)
    }

    nonisolated static func normalize(_ dtos: [ProductDTO]) -> ProductCatalogLoadResult {
        var products: [Product] = []
        var skipped: [SkippedProduct] = []

        for dto in dtos {
            guard let netContent = dto.netContent else {
                skipped.append(SkippedProduct(id: dto.id, name: dto.name, reason: "missing netContent"))
                continue
            }

            guard let baseQuantity = UnitNormalizer.baseQuantity(from: netContent) else {
                skipped.append(SkippedProduct(id: dto.id, name: dto.name, reason: "unrecognized unit '\(netContent.unit)'"))
                continue
            }

            guard let category = dto.category else {
                skipped.append(SkippedProduct(id: dto.id, name: dto.name, reason: "missing category"))
                continue
            }

            let nutrition = NutritionFacts(
                energyKcal: dto.nutrition.energyKcal100g ?? 0,
                proteins: dto.nutrition.proteins100g ?? 0,
                carbohydrates: dto.nutrition.carbohydrates100g ?? 0,
                sugars: dto.nutrition.sugars100g ?? 0,
                fat: dto.nutrition.fat100g ?? 0,
                saturatedFat: dto.nutrition.saturatedFat100g ?? 0,
                fiber: dto.nutrition.fiber100g ?? 0,
                salt: dto.nutrition.salt100g ?? 0
            )

            products.append(
                Product(
                    id: dto.id,
                    name: dto.name,
                    departmentID: dto.department.id,
                    categoryID: category.id,
                    baseQuantity: baseQuantity,
                    price: Decimal(dto.price.amount),
                    nutrition: nutrition,
                    labelIDs: Set(dto.labels.map(\.id)),
                    allergenIDs: Set(dto.allergens.map(\.id))
                )
            )
        }

        return ProductCatalogLoadResult(products: products, skipped: skipped)
    }
}
