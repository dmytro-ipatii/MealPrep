//
//  CompletedProcessingMealPlanMessageView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct CompletedProcessingMealPlanMessageView: View {
    var title: String
    var message: String
    var actionLabel: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: DSSpace.xxl.value) {

            VStack {
                Text(title)
                    .font(.dsBody)

                Text(message)
                    .font(.dsFootnote)
                    .foregroundStyle(DSColor.textSecondary.value)
                    .multilineTextAlignment(.center)
            }


            DSButtonView(label: actionLabel, action: action)

        }
        .padding(DSSpace.lg.value)
    }
}

#Preview {
    CompletedProcessingMealPlanMessageView(
        title: "Meal plan confirmed!",
        message: "Your meal plan is ready. Let's take a look at your plan.",
        actionLabel: "View plan",
        action: {
            
        }
    )
}
