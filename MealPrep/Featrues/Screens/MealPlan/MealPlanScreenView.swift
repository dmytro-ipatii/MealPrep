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

    init(modelManager: ModalManager, configurationStore: ConfigurationStoring, onComplete: @escaping () -> Void) {
        self.viewModel = ViewModel(modelManager: modelManager, configurationStore: configurationStore)
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
        .fullScreenCover(
            isPresented: $viewModel.isProcessingViewPresent,
            content: {
                VStack {
                    
                    switch viewModel.processMealPlanState {
                    case .processing:
                        MealPlanStateProcessingView()
                            .interactiveDismissDisabled(true)
                        
                    case .complete:
                        CompletedProcessingMealPlanMessageView(
                            title: "Meal plan confirmed!",
                            message: "Your meal plan is ready. Let's take a look at your plan.",
                            actionLabel: "View plan",
                            action: {
                                onComplete()
                            }
                        )
                    .interactiveDismissDisabled(true)

                case .error(let string):
                        CompletedProcessingMealPlanMessageView(
                            title: "Something went wrong",
                            message: string,
                            actionLabel: "Go back",
                            action: {
                                viewModel.closeProcessingView()
                            }
                        )
                }


            }
        })

        .padding( DSSpace.lg.value)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DSColor.backgroundPrimary.value.ignoresSafeArea(.all))
    }
}


#Preview {

    MealPlanScreenView(modelManager: ModalManager(), configurationStore: PreviewConfigurationStore(), onComplete: ({}))

}
