//
//  MealPlanScreenViewModel.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

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

            onComplete()
        }

        func navigateBack(onComplete: @escaping () -> Void ) {

            guard !sectionsHistory.isEmpty else {
                return
            }

            sectionsHistory.removeLast()

            guard let prevSection = sectionsHistory.last else {

                if !completedSections.isEmpty {
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
                } else {
                    onComplete()
                }


                return
            }

            section = prevSection

        }

        private func navigate(to section: MealPlanSection) {
            self.section = section

            if !sectionsHistory.contains(section) {
                sectionsHistory.append(section)
            }

        }

        private func setCompletedSection() {
            if !completedSections.contains(section) {
                completedSections.append(section)
            }
        }

    }
}
