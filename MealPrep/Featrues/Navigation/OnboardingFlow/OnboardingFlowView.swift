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

    @State private var paths: [Path] = []

    let onComplete: () -> Void

    var body: some View {
        NavigationStack(path: $paths) {
            LanderScreenView(action: {
                paths.append(.mealPlan)
            })
            .navigationDestination(for: Path.self) { path  in
                switch path {
                case .mealPlan:
                    MealPlanScreenView(onComplete: onComplete)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }

    }
}

#Preview {
    OnboardingFlowView(onComplete: ({}))
}
