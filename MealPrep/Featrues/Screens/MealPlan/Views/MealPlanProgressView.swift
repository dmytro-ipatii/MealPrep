//
//  MealPlanProgressView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct MealPlanProgressView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: MealPlanScreenView.ViewModel

    var body: some View {
        HStack {
            DSIconButtonView(icon: .chevronLeft, action: ({
                viewModel.navigateBack {
                    dismiss()
                }
            }))

            DSLinearProgressView(value: $viewModel.progress, total: viewModel.total)
        }
    }
}

#Preview {
    MealPlanProgressView(viewModel: MealPlanScreenView.ViewModel(modelManager: ModalManager(), configurationStore: PreviewConfigurationStore()))
        .padding()
}

