//
//  BaseQuantity.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// A product's package size, normalized at catalog load time. Downstream code
/// must never parse a raw quantity string like `"1 l"` — everything works in
/// grams, millilitres, or item counts.
nonisolated enum BaseQuantity: Sendable, Hashable {
    case mass(grams: Double)
    case volume(milliliters: Double)
    case count(Int)

    /// The unit a quantity of this product is expressed in.
    var unitLabel: String {
        switch self {
        case .mass: "g"
        case .volume: "ml"
        case .count: "ct"
        }
    }
}
