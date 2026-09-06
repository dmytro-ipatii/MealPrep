//
//  DSButtonVariant.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//


enum DSButtonVariant {
    case primary
    case secondary

    var appearance: DSButtonAppearance {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        }
    }
}