//
//  MealPlanScreenViewModel.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 05/09/2026.
//

import Foundation

enum ProcessMealPlanState {
    case processing(message: String)
    case complete
    case error(String)
}

extension MealPlanScreenView {

    @MainActor
    @Observable
    final class ViewModel {

        private let modelManager: ModalManager
        private let configurationStore: ConfigurationStoring
        private let generator: MealPlanGenerator
        private let mealPlanRepository: MealPlanRepositoryProtocol
        private var generationTask: Task<Void, Never>?

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

        var processMealPlanState: ProcessMealPlanState = .processing(message: "")
        var isProcessingViewPresent: Bool = false

        init(
            modelManager: ModalManager,
            configurationStore: ConfigurationStoring,
            generator: MealPlanGenerator,
            mealPlanRepository: MealPlanRepositoryProtocol
        ) {
            self.modelManager = modelManager
            self.configurationStore = configurationStore
            self.generator = generator
            self.mealPlanRepository = mealPlanRepository

            section = MealPlanSection.initial
            sectionsHistory = [MealPlanSection.initial]
            completedSections = []
            progress = 0

            let budgetRangeValue: ClosedRange<Double> = 25...150
            budgetRange = budgetRangeValue

            if let savedConfiguration = configurationStore.loadConfiguration() {
                budget = NSDecimalNumber(decimal: savedConfiguration.weeklyBudget).doubleValue
                dietaryNeeds = savedConfiguration.dietaryNeeds.map(Diet.init(dietaryNeed:))
                nutritionalGoal = savedConfiguration.goals.map(Nutrition.init(nutritionalGoal:))
            } else {
                budget = budgetRangeValue.lowerBound
            }
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

            let configuration = persistConfiguration()

            processMealPlanState = .processing(message: GenerationProgress.loadingCatalog.message)
            isProcessingViewPresent = true

            generationTask = Task { [weak self] in
                await self?.runGeneration(for: configuration)
            }
        }

        private func runGeneration(for configuration: MealPlanConfiguration) async {
            do {
                for try await progress in generator.generate(configuration: configuration) {
                    if case .finished(let plan) = progress {
                        // Persist only on complete success — a cancelled or
                        // failed run must leave no half-plan behind.
                        try mealPlanRepository.save(plan)
                        processMealPlanState = .complete
                    } else {
                        processMealPlanState = .processing(message: progress.message)
                    }
                }
            } catch is CancellationError {
                isProcessingViewPresent = false
            } catch {
                processMealPlanState = .error(Self.userFacingMessage(for: error))
            }
        }

        private static func userFacingMessage(for error: Error) -> String {
            switch error {
            case GenerationError.budgetInfeasible(let message):
                message
            case GenerationError.couldNotSatisfyConstraints:
                "We couldn't build a plan that fits all of your requirements. Try raising the budget or relaxing one of them."
            case MealPlanLLMError.missingAPIKey:
                "The app is missing its API key, so it can't generate a plan."
            default:
                "Something went wrong while building your plan. Please try again."
            }
        }

        func closeProcessingView() {
            generationTask?.cancel()
            generationTask = nil
            isProcessingViewPresent = false
            processMealPlanState = .processing(message: "")
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

        @discardableResult
        private func persistConfiguration() -> MealPlanConfiguration {
            let configuration = MealPlanConfiguration(
                weeklyBudget: Decimal(budget),
                currencyCode: "EUR",
                dietaryNeeds: Set(dietaryNeeds.compactMap(\.dietaryNeed)),
                goals: Set(nutritionalGoal.compactMap(\.nutritionalGoal)),
                servings: 1,
                createdAt: Date()
            )

            configurationStore.save(configuration)
            return configuration
        }

    }
}
