//
//  PantryStaple.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

/// A fixed, code-owned list of staples assumed already owned by the user.
///
/// Every case must be safe for all five `DietaryNeed` values by construction —
/// that is why butter, honey, stock cubes, and soy sauce are absent. Anything
/// requiring a check against the user's configuration is not a staple; it is a
/// catalog product. Staples are free and excluded from the cost calculator and
/// shopping list.
enum PantryStaple: String, Codable, CaseIterable, Sendable {
    case salt
    case blackPepper
    case oliveOil
    case vegetableOil
    case vinegar
    case water
    case garlicPowder
    case driedHerbs
    case groundSpices
    case bakingSoda
}
