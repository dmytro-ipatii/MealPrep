//
//  WeeklyMealPlanScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeeklyMealPlanScreenView: View {
    let plan: MealPlan

    @State private var selectedDay: WeekDay

    init(plan: MealPlan) {
        self.plan = plan
        self.selectedDay = WeekDay(date: .now) ?? .monday
    }

    var body: some View {
        VStack(spacing: DSSpace.sm.value) {

            Section {

                titleView

                // Budget
                BudgetBoxsView(budget: NSDecimalNumber(decimal: plan.totalCost).doubleValue)

            }
            .padding(.horizontal,DSSpace.lg.value)

            VStack(spacing: 32) {
                // Week day selection
                WeekDayPickerView(selection: $selectedDay)

                // Weak meal plans
                WeekMealPlanSliderView(weekDay: $selectedDay, plan: plan)
                    .ignoresSafeArea(.all)

            }



        }
        .padding(.top, DSSpace.lg.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DSColor.accent.value)
    }

    private var titleView: some View {
        Text("Buon appetit!")
            .font(.dsTitleL)
            .foregroundStyle(DSColor.textVibrantPrimary.value)
            .frame(height: 52)
    }
}

#Preview {
    WeeklyMealPlanScreenView(plan: .preview)
}
