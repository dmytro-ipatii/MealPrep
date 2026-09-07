//
//  StoredShoppingLine.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation
import SwiftData

@Model
final class StoredShoppingLine {
    var productID: String
    var productNameSnapshot: String
    var packages: Int
    var requiredQuantity: Double
    var purchasedQuantity: Double
    var quantityUnit: String
    var cost: Decimal

    init(
        productID: String,
        productNameSnapshot: String,
        packages: Int,
        requiredQuantity: Double,
        purchasedQuantity: Double,
        quantityUnit: String,
        cost: Decimal
    ) {
        self.productID = productID
        self.productNameSnapshot = productNameSnapshot
        self.packages = packages
        self.requiredQuantity = requiredQuantity
        self.purchasedQuantity = purchasedQuantity
        self.quantityUnit = quantityUnit
        self.cost = cost
    }
}
