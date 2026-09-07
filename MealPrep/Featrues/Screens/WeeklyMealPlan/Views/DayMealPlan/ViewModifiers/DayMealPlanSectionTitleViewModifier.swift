//
//  DayMealPlanSectionTitleViewModifier.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct DayMealPlanSectionTitleViewModifier: ViewModifier {

    var font: Font

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(DSColor.textPrimary.value)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
