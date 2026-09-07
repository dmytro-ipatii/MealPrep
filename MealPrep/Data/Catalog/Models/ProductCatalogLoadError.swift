//
//  ProductCatalogLoadError.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


enum ProductCatalogLoadError: Error {
    case resourceNotFound
    case decodingFailed(Error)
}