//
//  StoredIngredient.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation
import SwiftData

@Model
final class StoredIngredient {
    /// SwiftData relationship arrays come back unordered, so the order the
    /// model listed the ingredients in — which the recipe lines follow — has
    /// to be stored explicitly.
    var position: Int
    var productID: String
    var productNameSnapshot: String
    var quantityValue: Double
    var quantityUnit: String
    var costShare: Decimal

    init(
        position: Int,
        productID: String,
        productNameSnapshot: String,
        quantityValue: Double,
        quantityUnit: String,
        costShare: Decimal
    ) {
        self.position = position
        self.productID = productID
        self.productNameSnapshot = productNameSnapshot
        self.quantityValue = quantityValue
        self.quantityUnit = quantityUnit
        self.costShare = costShare
    }
}
