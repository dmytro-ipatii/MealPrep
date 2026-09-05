//
//  DSCornerRadius.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum DSCornerRadius {
    case none
    case full
    case sm
    case md
    case lg
    case xl

    var value: CGFloat {
        switch self {
        case .none: 0
        case .full: 9999
        case .sm: 12
        case .md: 16
        case .lg: 20
        case .xl: 34
        }
    }
}
