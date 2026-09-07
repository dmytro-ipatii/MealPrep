//
//  WeekDayPickerView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeekDayPickerView: View {
    @Binding var selection: WeekDay

    var body: some View {
        LazyHGrid(
            rows: [GridItem(.flexible(minimum: 47))],
            spacing: DSSpace.xxs.value,

        ) {
            ForEach(WeekDay.allCases) { day in
                DSChipView(
                    title: day.abbreviation,
                    isSelected: selection == day,
                    action: ({
                        selection = day
                    })
                )
            }
        }
        .frame(height: 40)
        .padding(.horizontal,DSSpace.lg.value)
    }
}
