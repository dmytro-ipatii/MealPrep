//
//  MealPlanStateProcessingView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct MealPlanStateProcessingView: View {
    /// Generation takes 20-60 seconds across several calls, so the current
    /// stage is shown rather than a bare spinner, which reads as a hang.
    var message: String = "Processing..."

    var body: some View {
        VStack {
            ZStack {
                Image(.mealBag)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(height: 200)

                EmojiWaterfallView()
                    .frame(height: 200)
            }

            Text(message)
                .font(.dsBody)
                .foregroundStyle(DSColor.textPrimary.value)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: message)
        }
    }
}

#Preview {
    MealPlanStateProcessingView(message: "Writing recipes… 3 of 7 days")
}

