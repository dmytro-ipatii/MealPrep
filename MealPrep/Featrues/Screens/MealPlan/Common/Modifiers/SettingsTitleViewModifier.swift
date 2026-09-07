//
//  SettingsTitleViewModifier.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct SettingsTitleViewModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .font(.dsTitle)
            .foregroundStyle(DSColor.textPrimary.value)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

}
