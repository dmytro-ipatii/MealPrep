//
//  Basket.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

struct Basket: Sendable, Equatable {
    let lines: [BasketLine]

    var totalCost: Decimal { lines.reduce(0) { $0 + $1.cost } }
    var totalWasteQuantity: Double { lines.reduce(0) { $0 + $1.wasteQuantity } }
    var skuCount: Int { lines.count }
}
