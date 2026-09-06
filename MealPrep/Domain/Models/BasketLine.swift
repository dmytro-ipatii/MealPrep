//
//  BasketLine.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// One product's contribution to the week's shopping basket, under
/// whole-package costing: using 200 ml from a 1 L carton still costs the
/// full carton price.
///
/// Named `requiredQuantity`/`purchasedQuantity` rather than the plan's
/// illustrative `requiredGrams`/`purchasedGrams` — the catalog has both mass
/// and volume products, so the quantity is in the product's own base unit
/// (grams, millilitres, or item count), not always grams.
struct BasketLine: Sendable, Equatable {
    let product: Product
    let requiredQuantity: Double
    let packages: Int
    let purchasedQuantity: Double
    let cost: Decimal

    var wasteQuantity: Double { purchasedQuantity - requiredQuantity }
    var utilization: Double { purchasedQuantity > 0 ? requiredQuantity / purchasedQuantity : 0 }
}
