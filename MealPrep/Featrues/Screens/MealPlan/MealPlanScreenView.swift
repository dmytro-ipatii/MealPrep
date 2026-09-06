//
//  MealPlanScreenView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct MealPlanScreenView: View {

    @State private var viewModel: ViewModel

    let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.viewModel = ViewModel()
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: DSSpace.lg.value) {

            MealPlanProgressView(viewModel: viewModel)

            switch viewModel.section {
            case .budget:
                BudgetSelectionView(viewModel: viewModel)
            case .dietry:
                DietryNeedsSectionView(viewModel: viewModel)
            case .nutrition:
                NutritionalGoalSectionView(viewModel: viewModel, onComplete: onComplete)
            }

        }
        .padding( DSSpace.lg.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.backgroundPrimary.value.ignoresSafeArea(.all))
    }
}



#Preview {
    MealPlanScreenView(onComplete: ({}))
}
