//
//  WeeklyMealPlanFlowView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct WeeklyMealPlanFlowView: View {
    let plan: MealPlan

    var body: some View {
        WeeklyMealPlanScreenView(plan: plan)
    }
}

#Preview {
    WeeklyMealPlanFlowView(plan: .preview)
}
