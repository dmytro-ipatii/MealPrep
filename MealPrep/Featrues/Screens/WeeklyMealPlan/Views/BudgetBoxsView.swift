//
//  BudgetBoxsView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct BudgetBoxsView: View {
    var title: String = "Est. cost"
    var budget: Double
    var perPeriod: String = "week"

    var body: some View {
        VStack(spacing: DSSpace.xxs.value) {

            Text(title)
                .font(.dsBody)
                .foregroundStyle(DSColor.textSecondary.value)

            Text("€\(budget.toFormatedString(with: 2)) / \(perPeriod)")
                .font(.dsHeadline)
                .foregroundStyle(DSColor.textPrimary.value)
        }
        .padding(.vertical, DSSpace.xs.value)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .dsBackground(color: DSColor.backgroundPrimary, radius: .md)
    }
}
