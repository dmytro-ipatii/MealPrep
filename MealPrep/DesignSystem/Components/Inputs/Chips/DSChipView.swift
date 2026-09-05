//
//  DSChipView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSChipView: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    private var background: DSColor {
        isSelected ? .black : .white
    }

    private var foreground: DSColor {
        isSelected ? .white : .black
    }
    var body: some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .font(.dsFootnote)
                    .foregroundStyle(foreground.value)
            }
            .frame(height: 40)
            .padding(.horizontal, DSSpace.sm.value)
            .dsBackground(color: background, radius: .sm)
        }
    }
}

#Preview("Preview") {
    VStack {
        DSChipView(title: "Mon", isSelected: false, action: ({}))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        DSColor.accent.value.ignoresSafeArea(.all)
    )
}

#Preview("Active") {
    VStack {
        DSChipView(title: "Mon", isSelected: true, action: ({}))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        DSColor.accent.value.ignoresSafeArea(.all)
    )
}
