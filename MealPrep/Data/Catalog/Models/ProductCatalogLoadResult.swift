//
//  ProductCatalogLoadResult.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


struct ProductCatalogLoadResult: Sendable {
    let products: [Product]
    let skipped: [SkippedProduct]
}