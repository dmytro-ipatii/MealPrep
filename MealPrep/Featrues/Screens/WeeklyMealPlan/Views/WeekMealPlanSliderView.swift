//
//  WeekMealPlanSliderView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeekMealPlanSliderView: View {
    @Binding var weekDay: WeekDay
    let plan: MealPlan

    @State private var scrollPosition: WeekDay?

    private let peekWidth: CGFloat = DSSpace.xl.value
    private let itemSpacing: CGFloat = DSSpace.sm.value

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: itemSpacing) {
                ForEach(WeekDay.allCases) { day in
                    DayMealPlanView(weekDay: day, day: plan.days.first { $0.dayIndex == day.dayIndex })
                        .containerRelativeFrame(.horizontal, count: 1, spacing: itemSpacing)
                        .id(day)
                }
            }
            .scrollTargetLayout()
        }
        .safeAreaPadding(.horizontal, peekWidth)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .onAppear {
            scrollPosition = weekDay
        }
        .onChange(of: scrollPosition) { _, newValue in
            guard let newValue, newValue != weekDay else { return }
            weekDay = newValue
        }
        .onChange(of: weekDay) { _, newValue in
            guard scrollPosition != newValue else { return }
            withAnimation {
                scrollPosition = newValue
            }
        }
    }
}



#Preview {
    VStack {
        WeekMealPlanSliderView(weekDay: .constant(.monday), plan: .preview)
    }
    .padding(.vertical)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(DSColor.accent.value.ignoresSafeArea())
}
