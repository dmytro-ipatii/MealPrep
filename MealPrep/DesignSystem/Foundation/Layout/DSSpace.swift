//
//  DSSpace.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum DSSpace {
    case none
    case xxs
    case xs
    case sm
    case md
    case lg
    case xl
    case xxl
    case xxxl

    var value: CGFloat {
        switch  self {
        case .none: 0
        case .xxs: 4
        case .xs: 8
        case .sm: 12
        case .md: 16
        case .lg: 20
        case .xl: 24
        case .xxl: 28
        case .xxxl: 58
        }
    }

}
