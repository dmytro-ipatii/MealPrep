//
//  ContentView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import SwiftUI

struct ContentView: View {
    @State var isUserPassedOnboarding: Bool = false

    var body: some View {
        if isUserPassedOnboarding {
            WeeklyMealPlanFlowView()
        } else {
            OnboardingFlowView(onComplete: ({ isUserPassedOnboarding = true}))
        }

    }
}

#Preview {
    ContentView()
}
