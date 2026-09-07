//
//  SelectionSectionView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct SelectionSectionView<Option: SettingsGridProtocol>: View {

    let title: String

    let options: [Option]

    let actionLabel: String
    let onActionPress: (_ selections: [Option]) -> Void

    @State private var selections: [Option] = []

    private var isActionDisabled: Bool {
        selections.isEmpty
    }

    init(
        title: String,
        selections: [Option],
        options: [Option],
        actionLabel: String = "Continue",
        onActionPress: @escaping ( _ : [Option]) -> Void,
    ) {
        self.title = title
        // Must go through the projected value: assigning to a @State property
        // inside init is ignored, which left previously saved selections
        // showing as unselected when reopening these screens to update a plan.
        self._selections = State(initialValue: selections)
        self.options = options
        self.actionLabel = actionLabel
        self.onActionPress = onActionPress
    }

    var body: some View {
        MealPlanSectionWrapperView(
            title: title,
            content: { gridView },
            action: { actionButton }
        )
    }

    private var gridView: some View {
        SettingsGridView(
            selection: selections,
            options: options,
            onSelect: { diet in

                if selections.contains(diet) {
                    selections.removeAll(where: { $0 == diet })
                } else {
                    selections.append(diet)
                }
            }
        )
    }

    private var actionButton: some View {
        DSButtonView(
            label: actionLabel,
            isDisabled: isActionDisabled,
            action: ({ onActionPress(selections)})
        )
    }
}
