//
//  View+Background.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

extension View {

    func dsBackground(color: DSColor, radius: DSCornerRadius = .none) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius.value)
                .fill(color.value)
        )
    }

}
