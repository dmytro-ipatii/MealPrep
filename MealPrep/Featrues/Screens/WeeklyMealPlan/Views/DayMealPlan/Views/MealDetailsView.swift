//
//  MealDetailsView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct MealDetailsView: View {
    let meal: PlannedMeal

    private var costPerServing: Double {
        let servings = max(meal.servings, 1)
        return NSDecimalNumber(decimal: meal.estimatedCost).doubleValue / Double(servings)
    }

    var body: some View {
        VStack(spacing: DSSpace.xs.value) {
            Text(meal.name)
                .modifier(DayMealPlanSectionTitleViewModifier(font: .dsBody))

            HStack(spacing: DSSpace.xs.value) {

                DSLabelWithIconView(icon: .clock, label: "\(meal.prepTimeMinutes) min")

                DSLabelWithIconView(
                    icon: .user,
                    label: "\(meal.servings) serving\(meal.servings == 1 ? "" : "s")"
                )

                DSLabelWithIconView(icon: .cash, label: "€ \(costPerServing.toFormatedString(with: 2)) / serving")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    MealDetailsView(meal: MealPlan.preview.days[0].meals[0])
}
