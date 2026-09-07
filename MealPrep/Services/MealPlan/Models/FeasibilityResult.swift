//
//  FeasibilityResult.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//

import Foundation

enum FeasibilityResult: Sendable, Equatable {
    case feasible
    case infeasible(minimumCost: Decimal, message: String)
}
