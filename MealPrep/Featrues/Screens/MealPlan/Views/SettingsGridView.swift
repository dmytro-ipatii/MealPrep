//
//  SettingsGridView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct SettingsGridView<Option: SettingsGridProtocol>: View {

    var selection: [Option]
    var options: [Option]
    let onSelect: (Option) -> Void

    private var columns: [GridItem] = [
        GridItem(.adaptive(minimum: .infinity, maximum: 168), spacing: DSSpace.md.value),
        GridItem(.adaptive(minimum: .infinity, maximum: 168),  spacing: DSSpace.md.value),
    ]

    init(
        selection: [Option],
        options: [Option],
        onSelect: @escaping (Option) -> Void
    ) {
        self.selection = selection
        self.options = options
        self.onSelect = onSelect
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            spacing: DSSpace.md.value,
            content: {

                ForEach(options) { option in
                    SettingGridItemView(
                        label: option.label,
                        emoji: option.emoji,
                        isSelected: selection.contains(option)
                    )
                    .onTapGesture {
                        onSelect(option)
                    }
                }
            }
        )
    }
}

private struct SettingGridItemView: View {
    let label: String
    let emoji: String
    var isSelected: Bool

    private var background: DSColor {
        isSelected ? DSColor.accent : DSColor.backgroundSecondary
    }
    private var foreground: Color {
        isSelected ? DSColor.white.value : DSColor.textPrimary.value
    }

    init(
        label: String,
        emoji: String,
        isSelected: Bool
    ) {
        self.label = label
        self.emoji = emoji
        self.isSelected = isSelected
    }

    var body: some View {
        VStack(alignment: .center, spacing: DSSpace.xxs.value) {

            if !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 32))
            }

            Text(label)
                .font(.dsBody)
                .foregroundStyle(foreground)

        }
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .dsBackground(color: background, radius: DSCornerRadius.lg)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }

}

#Preview("Preview") {
    SettingsGridView(selection: [], options: Diet.allCases, onSelect: ({ _ in }))
}

#Preview("With selection") {
    SettingsGridView(selection: [Diet.allCases[1], Diet.allCases[2]], options: Diet.allCases, onSelect: ({ _ in }))
}
