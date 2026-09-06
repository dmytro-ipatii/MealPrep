//
//  OnboardingFlowView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

enum Path: Hashable {
    case mealPlan
}

struct OnboardingFlowView: View {

    @Environment(ModalManager.self) private var modelManager
    @State private var paths: [Path] = []

    let configurationStore: ConfigurationStoring
    let generator: MealPlanGenerator
    let mealPlanRepository: MealPlanRepositoryProtocol
    let onComplete: () -> Void

    var body: some View {
        NavigationStack(path: $paths) {
            LanderScreenView(action: {
                paths.append(.mealPlan)
            })
            .navigationDestination(for: Path.self) { path  in
                switch path {
                case .mealPlan:
                    MealPlanScreenView(
                        modelManager: modelManager,
                        configurationStore: configurationStore,
                        generator: generator,
                        mealPlanRepository: mealPlanRepository,
                        onComplete: onComplete
                    )
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .showDSAlert(with: modelManager)

    }
}

#Preview {
    OnboardingFlowView(
        configurationStore: PreviewConfigurationStore(),
        generator: MealPlanGenerator(client: PreviewMealPlanLLMClient()),
        mealPlanRepository: PreviewMealPlanRepository(),
        onComplete: ({})
    )
    .environment(ModalManager())
}
