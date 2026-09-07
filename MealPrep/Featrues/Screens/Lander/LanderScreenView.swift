//
//  LanderScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct LanderScreenView: View {

    let action: () -> Void

    @State private var isIntroComplete = false

    var body: some View {
        VStack {
            Text("MealPrep")
                .font(.dsDisplayL)
                .foregroundStyle(DSColor.textPrimary.value)
                .opacity(isIntroComplete ? 1 : 0)

            Spacer()

            ShopBagWithScatteredItemsView(onAnimationComplete: {
                withAnimation(.easeOut(duration: 0.4)) {
                    isIntroComplete = true
                }
            })

            Spacer()

            DSButtonView(label: "Create your meal plan", action: action)
                .opacity(isIntroComplete ? 1 : 0)
        }
        .padding( DSSpace.lg.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.backgroundPrimary.value.ignoresSafeArea(.all))
    }
}

#Preview {
    LanderScreenView(action: ({}))
}
