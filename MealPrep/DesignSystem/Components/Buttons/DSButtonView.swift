//
//  DSButtonView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSButtonView: View {
    private let label: String
    private let variant: DSButtonVariant
    private var isLoading: Bool = false
    private var isDisabled: Bool = false

    private let action: () -> Void

    init(
        label: String,
        variant: DSButtonVariant = .primary,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.variant = variant
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    private var appearance: DSButtonAppearance {
        variant.appearance
    }

    private var isActionDisabled: Bool {
        isDisabled || isLoading
    }

    private var background: DSColor {
        isDisabled ? DSColor.backgroundSecondary : appearance.background
    }

    private var foreground: DSColor {
        isDisabled ? DSColor.textQuaternary : appearance.foreground
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
                            .foregroundStyle(foreground.value)
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

#Preview("Primary") {
    VStack {
        DSButtonView(label: "Create your meal plan", action: ({}))

        DSButtonView(
            label: "Create your meal plan",
            isLoading: true,
            action: ({})
        )

        DSButtonView(
            label: "Create your meal plan",
            isDisabled: true,
            action: ({})
        )
    }
    .padding()
}

#Preview("Secondary") {
    VStack {
        DSButtonView(
            label: "Create your meal plan",
            variant: .secondary,
            action: ({})
        )

        DSButtonView(
            label: "Create your meal plan",
            variant: .secondary,
            isLoading: true,
            action: ({})
        )

        DSButtonView(
            label: "Create your meal plan",
            variant: .secondary,
            isDisabled: true,
            action: ({})
        )
    }
    .padding()
}

