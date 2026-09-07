//
//  ShoppingLine.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// One line of the week's shopping list, snapshotted.
///
/// `BasketLine` carries a whole `Product` because it is a computation
/// artifact. A finished plan must outlive the catalog it was built from — the
/// bundled JSON can change with any app update — so what gets stored and
/// rendered is this, with the name and numbers copied in.

struct ShoppingLine: Sendable, Equatable {
    let productID: String
    let productName: String
    let packages: Int
    let requiredQuantity: Double
    let purchasedQuantity: Double
    let unit: String
    let cost: Decimal

    var wasteQuantity: Double { purchasedQuantity - requiredQuantity }
    var utilization: Double { purchasedQuantity > 0 ? requiredQuantity / purchasedQuantity : 0 }
}

extension ShoppingLine {
    init(_ line: BasketLine) {
        self.init(
            productID: line.product.id,
            productName: line.product.name,
            packages: line.packages,
            requiredQuantity: line.requiredQuantity,
            purchasedQuantity: line.purchasedQuantity,
            unit: line.product.baseQuantity.unitLabel,
            cost: line.cost
        )
    }
}
