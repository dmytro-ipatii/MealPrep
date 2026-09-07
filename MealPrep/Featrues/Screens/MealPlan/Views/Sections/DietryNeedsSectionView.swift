//
//  DietryNeedsSectionView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct DietryNeedsSectionView: View {

    @Bindable var viewModel: MealPlanScreenView.ViewModel

    init(viewModel: MealPlanScreenView.ViewModel) {
        self._viewModel = Bindable(viewModel)

    }
    var body: some View {
        SelectionSectionView(
            title: "Any dietary needs?",
            selections: viewModel.dietaryNeeds,
            options: Diet.allCases,
            onActionPress: { selections in
                viewModel.setDietaryNeed(with: selections)
            }
        )
    }
}




