//
//  NutritionalGoalSettingsView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct NutritionalGoalSectionView: View {

    @Bindable private var viewModel: MealPlanScreenView.ViewModel
    let onComplete: () -> Void
    init(
        viewModel: MealPlanScreenView.ViewModel,
        onComplete: @escaping () -> Void
    ) {
        self._viewModel = Bindable(viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        SelectionSectionView(
            title: "Any nutritional goals?",
            selections: viewModel.nutritionalGoal,
            options: Nutrition.allCases,
            onActionPress: { selections in
                viewModel.setNutritionalGoal(with: selections, onComplete: onComplete)
            }
        )
    }

}

#Preview {
    NutritionalGoalSectionView(viewModel: MealPlanScreenView.ViewModel(modelManager: ModalManager(), configurationStore: PreviewConfigurationStore()), onComplete: ({}))
}
