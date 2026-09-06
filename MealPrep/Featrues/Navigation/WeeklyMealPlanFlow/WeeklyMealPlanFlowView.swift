//
//  WeeklyMealPlanFlowView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

/// Named distinctly rather than reusing the onboarding flow's `Path` — that
/// one is a top-level type that already shadows `SwiftUI.Path`.
enum WeeklyMealPlanPath: Hashable {
    case updateMealPlan
}

/// The app's home once a plan exists: the week, plus a way back into the
/// configuration screens to build a new one.
struct WeeklyMealPlanFlowView: View {

    @Environment(ModalManager.self) private var modelManager
    @State private var paths: [WeeklyMealPlanPath] = []
    @State private var plan: MealPlan

    private let configurationStore: ConfigurationStoring
    private let generator: MealPlanGenerator
    private let mealPlanRepository: MealPlanRepositoryProtocol

    init(
        plan: MealPlan,
        configurationStore: ConfigurationStoring,
        generator: MealPlanGenerator,
        mealPlanRepository: MealPlanRepositoryProtocol
    ) {
        self._plan = State(initialValue: plan)
        self.configurationStore = configurationStore
        self.generator = generator
        self.mealPlanRepository = mealPlanRepository
    }

    var body: some View {
        NavigationStack(path: $paths) {
            WeeklyMealPlanScreenView(
                plan: plan,
                onUpdatePlan: { paths.append(.updateMealPlan) }
            )
            .navigationDestination(for: WeeklyMealPlanPath.self) { path in
                switch path {
                case .updateMealPlan:
                    // The configuration screens open prefilled with the saved
                    // settings, so updating means adjusting rather than
                    // starting from scratch.
                    MealPlanScreenView(
                        modelManager: modelManager,
                        configurationStore: configurationStore,
                        generator: generator,
                        mealPlanRepository: mealPlanRepository,
                        onComplete: showUpdatedPlan
                    )
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
        .showDSAlert(with: modelManager)
    }

    private func showUpdatedPlan() {
        // Generation replaces the stored plan, so re-read rather than trusting
        // the copy this view was created with.
        if let updated = mealPlanRepository.loadLatestPlan() {
            plan = updated
        }
        paths.removeAll()
    }
}

#Preview {
    WeeklyMealPlanFlowView(
        plan: .preview,
        configurationStore: PreviewConfigurationStore(),
        generator: MealPlanGenerator(client: PreviewMealPlanLLMClient()),
        mealPlanRepository: PreviewMealPlanRepository()
    )
    .environment(ModalManager())
}
