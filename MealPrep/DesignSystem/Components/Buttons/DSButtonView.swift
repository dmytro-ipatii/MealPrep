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

    private var background: DSColor {
        isDisabled ? DSColor.backgroundSecondary : DSColor.accent
    }

    var body: some View {
        Button(
            action: action,
            label: {
                HStack {

                    if isLoading {
                        DSCircularProgressView()
                    } else {
                        Text(label)
                            .font(.dsBody)
                            .foregroundStyle(DSColor.white.value)
                    }

                }
                .frame(minHeight: 72)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, DSSpace.md.value)
                .dsBackground(color: background, radius: .full)
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
