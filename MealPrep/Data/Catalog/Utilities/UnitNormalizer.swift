//
//  UnitNormalizer.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// Converts a catalog `NetContentDTO` into a `BaseQuantity`. Returns `nil` for
/// a unit it doesn't recognize — the caller must exclude that product rather
/// than guess.
enum UnitNormalizer {
    nonisolated static func baseQuantity(from netContent: NetContentDTO) -> BaseQuantity? {
        switch netContent.unit.lowercased() {
        case "g":
            return .mass(grams: netContent.value)
        case "kg":
            return .mass(grams: netContent.value * 1000)
        case "ml":
            return .volume(milliliters: netContent.value)
        case "l":
            return .volume(milliliters: netContent.value * 1000)
        case "pcs", "piece", "pieces", "count":
            return .count(Int(netContent.value))
        default:
            return nil
        }
    }
}
