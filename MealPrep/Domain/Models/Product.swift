//
//  Product.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

struct Product: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let departmentID: String
    let categoryID: String
    let baseQuantity: BaseQuantity
    let price: Decimal
    let nutrition: NutritionFacts
    let labelIDs: Set<String>
    let allergenIDs: Set<String>
}
