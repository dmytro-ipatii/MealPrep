//
//  MealDetailsView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct MealDetailsView: View {
    var body: some View {
        VStack {
            Text("BBQ Chicken Loaded Jackets")
                .modifier(DayMealPlanSectionTitleViewModifier(font: .dsBody))

            HStack(spacing: DSSpace.xs.value) {

                DSLabelWithIconView(icon: .clock, label: "25 min")

                DSLabelWithIconView(icon: .user, label: "2 servings")

                DSLabelWithIconView(icon: .cash, label: "€ 4.18 / serving")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    MealDetailsView()
}
