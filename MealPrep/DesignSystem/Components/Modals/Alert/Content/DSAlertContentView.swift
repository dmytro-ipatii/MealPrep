//
//  DSAlertContentView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

public struct DSAlertContentView: View {
    private let content: ModalContent

    public init(
        content: ModalContent
    ) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .center, spacing: DSSpace.xl.value) {

            VStack(spacing: DSSpace.sm.value) {
                titleView

                if let message = content.message {
                    messageView(message)
                }
            }

            VStack {
                ForEach(content.buttons) { button in
                    DSButtonView(
                        label: button.label,
                        variant: button.variant,
                        action: button.action
                    )

                }
            }

        }
        .padding(DSSpace.lg.value)
        .frame(maxWidth: 340)
        .dsBackground(color: DSColor.backgroundPrimary, radius: DSCornerRadius.lg)

    }


    private var titleView: some View {
        Text(content.title)
            .font(.dsHeadline)
            .foregroundStyle(DSColor.textPrimary.value)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private func messageView(_ message: String) -> some View {
        Text(message)
            .font(.dsCallout)
            .foregroundStyle(DSColor.textSecondary.value)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    DSAlertContentView(
        content: .init(
            title: "Cancel your meal plan?",
            message: "You changes will be lost.",
            buttons: [
                ModalButton(label: "Cancel", variant: .primary, action: ({})),
                ModalButton(label: "Continue", variant: .secondary, action: ({})),
            ]
        )
    )
}
