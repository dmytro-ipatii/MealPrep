//
//  ContentView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State var isUserPassedOnboarding: Bool = false

    let configurationStore: ConfigurationStoring

    var body: some View {
        if isUserPassedOnboarding {
            WeeklyMealPlanFlowView()
        } else {
            OnboardingFlowView(
                configurationStore: configurationStore,
                onComplete: ({ isUserPassedOnboarding = true})
            )
        }

    }
}

#Preview {
    ContentView(configurationStore: PreviewConfigurationStore())
}
