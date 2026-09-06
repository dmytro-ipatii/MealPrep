//
//  WeeklyMealPlanScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeeklyMealPlanScreenView: View {
    private var budget: Double

    @State private var selectedDay: WeekDay

    init() {
        self.budget = 80
        self.selectedDay = WeekDay(date: .now) ?? .monday
    }

    var body: some View {
        VStack(spacing: DSSpace.sm.value) {

            Section {

                titleView

                // Budget
                BudgetBoxsView(budget: budget)

            }
            .padding(.horizontal,DSSpace.lg.value)

            VStack(spacing: 32) {
                // Week day selection
                WeekDayPickerView(selection: $selectedDay)

                // Weak meal plans
                WeekMealPlanSliderView(weekDay: $selectedDay)
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
    WeeklyMealPlanScreenView()
}
