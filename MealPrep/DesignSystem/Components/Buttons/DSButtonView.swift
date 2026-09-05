//
//  DSButtonView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSButtonView: View {
    let label: String
    var isLoading: Bool = false
    var isDisabled: Bool = false

    let action: () -> Void

    private var isActionDisabled: Bool {
        isDisabled || isLoading
    }

    private var background: Color {
        isDisabled ? DSColor.backgroundSecondary.value : DSColor.accent.value
    }

    var body: some View {
        Button(
            action: action,
            label: {
                HStack {

                    if isLoading {
                        ProgressView()
                            .tint(DSColor.ink.value)

                    } else {
                        Text(label)
                            .font(.dsBody)
                            .foregroundStyle(DSColor.white.value)
                    }

                }
                .frame(minHeight: 72)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DSSpace.md.value)
                .background(
                    RoundedRectangle(cornerRadius: DSCornerRadius.full.value)
                        .fill(background)
                )
            }
        )
        .disabled(isActionDisabled)
        .buttonStyle(.plain)
    }
}

#Preview("Active") {
    DSButtonView(label: "Create your meal plan", action: ({}))
        .padding()
}

#Preview("Loading") {
    DSButtonView(
        label: "Create your meal plan",
        isLoading: true,
        action: ({})
    )
    .padding()
}

#Preview("Disabled") {
    DSButtonView(
        label: "Create your meal plan",
        isDisabled: true,
        action: ({})
    )
    .padding()
}
