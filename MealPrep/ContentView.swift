//
//  ContentView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var storedPlan: MealPlan?
    @State private var hasCheckedForStoredPlan = false

    let configurationStore: ConfigurationStoring
    let generator: MealPlanGenerator
    let mealPlanRepository: MealPlanRepositoryProtocol

    var body: some View {
        Group {
            if let storedPlan {
                WeeklyMealPlanFlowView(plan: storedPlan)
            } else {
                OnboardingFlowView(
                    configurationStore: configurationStore,
                    generator: generator,
                    mealPlanRepository: mealPlanRepository,
                    onComplete: { storedPlan = mealPlanRepository.loadLatestPlan() }
                )
            }
        }
        .task {
            // A plan generated in a previous session reopens straight away.
            guard !hasCheckedForStoredPlan else { return }
            hasCheckedForStoredPlan = true

            #if DEBUG
            // Lets the plan screens be launched directly for inspection,
            // without spending a real generation run:
            // xcrun simctl launch <device> <bundle id> -seedPreviewPlan
            if ProcessInfo.processInfo.arguments.contains("-seedPreviewPlan") {
                storedPlan = .preview
                return
            }
            #endif

            storedPlan = mealPlanRepository.loadLatestPlan()
        }
    }
}

#Preview {
    ContentView(
        configurationStore: PreviewConfigurationStore(),
        generator: MealPlanGenerator(client: PreviewMealPlanLLMClient()),
        mealPlanRepository: PreviewMealPlanRepository()
    )
    .environment(ModalManager())
}
