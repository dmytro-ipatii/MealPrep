//
//  MealPlanStateProcessingView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct MealPlanStateProcessingView: View {
    var body: some View {
        VStack {
            Image(.mealBag)
                .resizable()
                .aspectRatio(1, contentMode: .fit)
                .frame(height: 200)

            Text("Processing...")
                .font(.dsBody)
                .foregroundStyle(DSColor.textPrimary.value)

        }
    }
}

#Preview {
    MealPlanStateProcessingView()
}

