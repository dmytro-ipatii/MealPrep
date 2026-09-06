//
//  DayMealPlanView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct DayMealPlanView: View {
    var weekDay: WeekDay

    var body: some View {
        VStack(spacing: DSSpace.xxl.value){

            Text(weekDay.name)
                .modifier(DayMealPlanSectionTitleViewModifier(font: .dsHeadline))

            // Meal Details
            MealDetailsView()

            // Ingredients
            VStack {
                Text("Ingredients")
                    .modifier(DayMealPlanSectionTitleViewModifier(font: .dsFootnote))
            }

            // Recipe
            VStack {
                Text("Recipe")
                    .modifier(DayMealPlanSectionTitleViewModifier(font: .dsFootnote))
            }

        }
        .padding(DSSpace.xl.value)
        .frame(maxWidth:  .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: DSCornerRadius.xl.value,
                topTrailing: DSCornerRadius.xl.value,
            ))
            .fill(DSColor.backgroundPrimary.value)
        )
    }
}

#Preview {
    VStack {
        DayMealPlanView(weekDay: .monday)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DSColor.accent.value.ignoresSafeArea())

}
