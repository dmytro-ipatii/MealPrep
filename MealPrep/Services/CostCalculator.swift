//
//  CostCalculator.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation

/// Aggregates ingredient usages into a priced `Basket` under whole-package
/// costing. A pure function over `[IngredientUsage]` — no I/O.
///
/// Algorithm: sum the required quantity per product across the whole week,
/// then `packages = ceil(required / packageSize)`, `cost = packages × price`.
/// Waste (`purchasedQuantity - requiredQuantity`) is a first-class output,
/// not a side effect — it's free to compute and useful to the user.
enum CostCalculator {

    static func basket(for usages: [IngredientUsage]) -> Basket {
        let usagesByProduct = Dictionary(grouping: usages, by: \.product.id)

        let lines: [BasketLine] = usagesByProduct.values.compactMap { group in
            guard let product = group.first?.product else { return nil }

            let requiredQuantity = group.reduce(0) { $0 + $1.quantity }
            let packageSize = quantity(for: product.baseQuantity)
            let packages = packageSize > 0 ? Int((requiredQuantity / packageSize).rounded(.up)) : 1
            let purchasedQuantity = Double(packages) * packageSize

            return BasketLine(
                product: product,
                requiredQuantity: requiredQuantity,
                packages: packages,
                purchasedQuantity: purchasedQuantity,
                cost: Decimal(packages) * product.price
            )
        }

        return Basket(lines: lines)
    }

    private static func quantity(for baseQuantity: BaseQuantity) -> Double {
        switch baseQuantity {
        case .mass(let grams): grams
        case .volume(let milliliters): milliliters
        case .count(let count): Double(count)
        }
    }
}
