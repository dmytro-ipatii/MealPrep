//
//  ProductDTO.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Mirrors `product_catalog_en.json` exactly. Decodable only, no business logic.
///
/// Optionality here follows the actual bundled data, not an idealized shape:
/// `category`, `netContent`, `unitPrice`, `quantity`, `nutriScore` and
/// `novaGroup` are `null` for a meaningful slice of rows, and every field in
/// `NutritionDTO` can individually be `null`.
struct ProductDTO: Decodable {
    let id: String
    let barcode: String?
    let name: String
    let brand: String?
    let department: TaxonomyRefDTO
    let category: TaxonomyRefDTO?
    let quantity: String?
    let netContent: NetContentDTO?
    let price: PriceDTO
    let unitPrice: UnitPriceDTO?
    let nutrition: NutritionDTO
    let nutriScore: String?
    let novaGroup: Int?
    let labels: [TaxonomyRefDTO]
    let allergens: [TaxonomyRefDTO]
}

struct TaxonomyRefDTO: Decodable {
    let id: String
    let name: String
}

struct NetContentDTO: Decodable {
    let value: Double
    let unit: String
}

struct PriceDTO: Decodable {
    let amount: Double
    let currency: String
}

struct UnitPriceDTO: Decodable {
    let amount: Double
    let unit: String
}

struct NutritionDTO: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let sugars100g: Double?
    let fat100g: Double?
    let saturatedFat100g: Double?
    let fiber100g: Double?
    let salt100g: Double?
}
