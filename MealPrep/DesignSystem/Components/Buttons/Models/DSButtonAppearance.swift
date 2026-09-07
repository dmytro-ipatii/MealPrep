//
//  DSButtonAppearance.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//


struct DSButtonAppearance {
    let background: DSColor
    let foreground: DSColor

    init(
        background: DSColor = DSColor.accent,
        foreground: DSColor =  DSColor.white
    ) {
        self.background = background
        self.foreground = foreground
    }

    static let primary: Self = .init()

    static let secondary: Self = .init(
        background: DSColor.backgroundSecondaryElevated,
        foreground: DSColor.textSecondary,
    )


}