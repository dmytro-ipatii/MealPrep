//
//  LanderScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct LanderScreenView: View {

    let action: () -> Void

    var body: some View {
        VStack {
            Text("MealPrep")
                .font(.dsDisplayL)
                .foregroundStyle(DSColor.textPrimary.value)

            Spacer()

            ShopBagWithScatteredItemsView()

            Spacer()

            DSButtonView(label: "Create your meal plan", action: action)
        }
        .padding( DSSpace.lg.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.backgroundPrimary.value.ignoresSafeArea(.all))
    }
}

#Preview {
    LanderScreenView(action: ({}))
}
