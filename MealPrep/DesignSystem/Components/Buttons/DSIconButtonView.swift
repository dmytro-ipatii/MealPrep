//
//  DSIconButtonView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DSIconButtonView: View {
    let icon: ImageResource
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                VStack {
                    Image(icon)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 20)
                }
                .padding(4)
                .dsBackground(color: .backgroundSecondary, radius: .full)
            }
        )
        .disabled(isDisabled)
        .buttonStyle(.plain)

    }
}

#Preview("Active") {
    DSIconButtonView(icon: .chevronLeft, action: ({}))
        .frame(width: 28)
}

#Preview("Disabled") {
    DSIconButtonView(
        icon: .chevronLeft,
        isDisabled: true,
        action: ({})
    )
}


