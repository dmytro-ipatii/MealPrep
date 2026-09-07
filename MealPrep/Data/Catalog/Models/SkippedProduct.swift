//
//  SkippedProduct.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


/// A catalog row that failed normalization, with the reason it was dropped.
struct SkippedProduct: Sendable, Equatable {
    let id: String
    let name: String
    let reason: String
}