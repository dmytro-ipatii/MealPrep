//
//  MealPlanScreenViewModel.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum ProcessMealPlanState {
    case processing
    case complete
    case error(String)
}

extension MealPlanScreenView {

    @MainActor
    @Observable
    final class ViewModel {

        private let modelManager: ModalManager

        var section: MealPlanSection
        var sectionsHistory: [MealPlanSection]

        private var completedSections: [MealPlanSection] {
            didSet {
                progress = CGFloat(completedSections.count)
            }
        }

        var progress: CGFloat
        var total: CGFloat = MealPlanSection.sectionsCount

        var budgetRange: ClosedRange<Double>
        var budget: Double

        var dietaryNeeds: [Diet] = []
        var nutritionalGoal: [Nutrition] = []

        var processMealPlanState: ProcessMealPlanState = .processing
        var isProcessingViewPresent: Bool = false

        init(modelManager: ModalManager) {
            self.modelManager = modelManager

            section = MealPlanSection.initial
            sectionsHistory = [MealPlanSection.initial]
            completedSections = []
            progress = 0

            let budgetRangeValue: ClosedRange<Double> = 25...150
            budgetRange = budgetRangeValue
            budget = budgetRangeValue.lowerBound

        }

        func setBudget(_ amount: Double)  {
            budget = amount

            setCompletedSection()

            navigate(to: .dietry)
        }

        func setDietaryNeed(with dietaryNeeds: [Diet]) {
            self.dietaryNeeds = dietaryNeeds

            setCompletedSection()

            navigate(to: .nutrition)
        }

        func setNutritionalGoal(with nutritionalGoal: [Nutrition], onComplete: @escaping () -> Void) {

            setCompletedSection()

            self.nutritionalGoal = nutritionalGoal

            Task {
                processMealPlanState = .processing
                isProcessingViewPresent = true

                try? await Task.sleep(for: .seconds(3))

                processMealPlanState = .complete
            }
            //onComplete()
        }

        func closeProcessingView() {
            isProcessingViewPresent = false
            processMealPlanState = .processing
        }

        func navigateBack(onComplete: @escaping () -> Void ) {

            guard sectionsHistory.count > 1 else {
                showDiscardAlert(onComplete: onComplete)
                return
            }

            sectionsHistory.removeLast()
            section = sectionsHistory.last!

        }

        private func showDiscardAlert(onComplete: @escaping () -> Void ) {
            modelManager.present(
                content: .init(
                    title: "Discard changes?",
                    message: "If you leave now, your changes will be lost.",
                    buttons: [
                        .init(label: "Keep editing", variant: .primary, action: ({
                            self.modelManager.dismiss()
                        })),
                        .init(label: "Discard changes", variant: .secondary, action: ({
                            self.modelManager.dismiss()
                            onComplete()
                        }))
                    ]
                )
            )
        }

        private func navigate(to section: MealPlanSection) {
            self.section = section

            sectionsHistory.append(section)

        }

        private func setCompletedSection() {
            if !completedSections.contains(section) {
                completedSections.append(section)
            }
        }

    }
}
