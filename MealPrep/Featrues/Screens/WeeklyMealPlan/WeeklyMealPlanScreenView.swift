//
//  WeeklyMealPlanScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeeklyMealPlanScreenView: View {
    let plan: MealPlan
    let onUpdatePlan: () -> Void

    @State private var selectedDay: WeekDay
    @State private var isSettingsPresented: Bool = false

    init(plan: MealPlan, onUpdatePlan: @escaping () -> Void = {}) {
        self.plan = plan
        self.onUpdatePlan = onUpdatePlan
        self.selectedDay = WeekDay(date: .now) ?? .monday
    }

    var body: some View {
        VStack(spacing: DSSpace.sm.value) {

            Section {

                titleView

                // Budget
                BudgetBoxsView(budget: NSDecimalNumber(decimal: plan.totalCost).doubleValue)

                //updatePlanButton
            }
            .padding(.horizontal, DSSpace.lg.value)

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
        .sheet(isPresented: $isSettingsPresented, content: {

            VStack {
                Text("Settings")
                    .modifier(DayMealPlanSectionTitleViewModifier(font: .dsHeadline))

                BudgetBoxsView(
                    title: "Budget",
                    budget: NSDecimalNumber(decimal: plan.totalCost).doubleValue
                )

                Spacer()

                updatePlanButton
            }
            .padding(DSSpace.xl.value)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DSColor.backgroundPrimary.value)
            .presentationDetents([.height(300)])

        })
        .overlay(alignment: .topTrailing) {
            VStack {
                Image(systemName: "gearshape.fill")
                    .font(.dsBody)
                    .foregroundStyle(.backgroundSecondary)
            }
            .padding(DSSpace.xxs.value)
            .offset(x: -20, y: 0)
            .onTapGesture {
                isSettingsPresented = true
            }
        }
    }

    private var updatePlanButton: some View {
        DSButtonView(label: "Update meal plan", variant: .primary, action: {
            isSettingsPresented = false

            onUpdatePlan()
        })
            .padding(.top, DSSpace.xs.value)
    }

    private var titleView: some View {
        Text("Buon appetit!")
            .font(.dsTitleL)
            .foregroundStyle(DSColor.textVibrantPrimary.value)
            .frame(height: 52)
    }
}

#Preview {


    NavigationStack {
        WeeklyMealPlanScreenView(plan: .preview, onUpdatePlan: {})
    }

}
