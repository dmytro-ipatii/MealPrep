//
//  MealPlanSectionWrapperView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct MealPlanSectionWrapperView<Content: View, Action: View>: View {
    var title: String
    var content: Content
    var action: Action

    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder action: () -> Action,
    ) {
        self.title = title
        self.content = content()
        self.action = action()
    }

    var body: some View {
        VStack {

            titleView

            Spacer()

            content

            Spacer()

            action

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var titleView: some View {
        Text(title)
            .modifier(SettingsTitleViewModifier())
    }
}
