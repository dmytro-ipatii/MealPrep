//
//  BudgetSelectionView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct BudgetSelectionView: View {

    @State private var value: Double

    @Bindable var viewModel: MealPlanScreenView.ViewModel

    init(viewModel: MealPlanScreenView.ViewModel) {
        self._viewModel = Bindable(viewModel)

        self._value = State(wrappedValue: viewModel.budget)
    }

    var body: some View {
        MealPlanSectionWrapperView(
            title: "What's your budget?",
            content: {
                BedgetSettingInputView(value: $value, range: viewModel.budgetRange)
            },
            action: {
                actionButtonView
            }
        )
    }

    private var actionButtonView: some View {
        DSButtonView(label: "Continue", action: ({
            viewModel.setBudget(value)
        }))
    }
}

private struct BedgetSettingInputView: View {
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: DSSpace.xxxl.value) {

            VStack(spacing: DSSpace.xxs.value) {

                valueView

                periodLabelView
            }

            sliderInputView
        }
    }

    private var valueView: some View {
        Text("€\(value.toFormatedString())")
            .font(.dsDisplayXL)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundStyle(
                LinearGradient(colors: [
                    DSColor.black.value,
                    DSColor.accent.value,
                    DSColor.black.value,
                    DSColor.black.value,
                ], startPoint: .leading, endPoint: .trailing)
            )
    }

    private var periodLabelView: some View {
        Text("per week")
            .font(.dsBody)
            .foregroundStyle(DSColor.textSecondary.value)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var sliderInputView: some View {
        DSSliderView(value: $value, range: range)
    }
}

#Preview {
    BudgetSelectionView(viewModel: MealPlanScreenView.ViewModel(
        modelManager: ModalManager(),
        configurationStore: PreviewConfigurationStore(),
        generator: MealPlanGenerator(client: PreviewMealPlanLLMClient()),
        mealPlanRepository: PreviewMealPlanRepository()
    ))
}
