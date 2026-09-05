//
//  DSColor.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

enum DSColor: String {
    case accent = "AccentColor"
    case backgroundPrimary
    case backgroundSecondary
    case backgroundSecondaryElevated
    case green
    case black
    case textPrimary
    case textQuaternary
    case textSecondary
    case textVibrantPrimary
    case white

    var value: Color {
        Color(self.rawValue, bundle: .main)
    }
}
