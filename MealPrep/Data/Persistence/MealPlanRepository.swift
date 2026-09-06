//
//  MealPlanRepository.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import SwiftData

@MainActor
protocol MealPlanRepositoryProtocol {
    /// The most recently generated plan, or nil if there is none.
    func loadLatestPlan() -> MealPlan?
    /// Replaces any stored plan. Called only on complete success — a
    /// cancelled or failed run must leave no half-plan behind.
    func save(_ plan: MealPlan) throws
    func deleteAll() throws
}

@MainActor
final class SwiftDataMealPlanRepository: MealPlanRepositoryProtocol {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadLatestPlan() -> MealPlan? {
        var descriptor = FetchDescriptor<StoredMealPlan>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let stored = try? modelContext.fetch(descriptor).first else { return nil }
        return Self.domainPlan(from: stored)
    }

    func save(_ plan: MealPlan) throws {
        // The app holds one plan at a time; generating a new one replaces it.
        try deleteAll()
        modelContext.insert(Self.storedPlan(from: plan))
        try modelContext.save()
    }

    func deleteAll() throws {
        try modelContext.delete(model: StoredMealPlan.self)
        try modelContext.save()
    }

    // MARK: - Domain to stored

    private static func storedPlan(from plan: MealPlan) -> StoredMealPlan {
        StoredMealPlan(
            generatedAt: plan.generatedAt,
            totalCost: plan.totalCost,
            totalWasteQuantity: plan.totalWasteQuantity,
            days: plan.days.map { day in
                StoredPlanDay(
                    dayIndex: day.dayIndex,
                    meals: day.meals.map(storedMeal(from:))
                )
            },
            shoppingList: plan.shoppingList.map { line in
                StoredShoppingLine(
                    productID: line.productID,
                    productNameSnapshot: line.productName,
                    packages: line.packages,
                    requiredQuantity: line.requiredQuantity,
                    purchasedQuantity: line.purchasedQuantity,
                    quantityUnit: line.unit,
                    cost: line.cost
                )
            },
            weeklyBudget: plan.configuration.weeklyBudget,
            currencyCode: plan.configuration.currencyCode,
            dietaryNeedsRaw: plan.configuration.dietaryNeeds.map(\.rawValue).sorted(),
            goalsRaw: plan.configuration.goals.map(\.rawValue).sorted(),
            servings: plan.configuration.servings,
            configurationCreatedAt: plan.configuration.createdAt
        )
    }

    private static func storedMeal(from meal: PlannedMeal) -> StoredMeal {
        StoredMeal(
            slotRaw: meal.slot.rawValue,
            name: meal.name,
            prepTimeMinutes: meal.prepTimeMinutes,
            servings: meal.servings,
            estimatedCost: meal.estimatedCost,
            recipeIngredientLines: meal.recipe.ingredientLines,
            recipeSteps: meal.recipe.steps,
            pantryItemsRaw: meal.pantryItems.map(\.rawValue),
            ingredients: meal.ingredients.enumerated().map { position, ingredient in
                StoredIngredient(
                    position: position,
                    productID: ingredient.productID,
                    productNameSnapshot: ingredient.productName,
                    quantityValue: ingredient.quantity,
                    quantityUnit: ingredient.unit,
                    costShare: ingredient.costShare
                )
            }
        )
    }

    // MARK: - Stored to domain

    private static func domainPlan(from stored: StoredMealPlan) -> MealPlan {
        MealPlan(
            generatedAt: stored.generatedAt,
            configuration: MealPlanConfiguration(
                weeklyBudget: stored.weeklyBudget,
                currencyCode: stored.currencyCode,
                dietaryNeeds: Set(stored.dietaryNeedsRaw.compactMap(DietaryNeed.init(rawValue:))),
                goals: Set(stored.goalsRaw.compactMap(NutritionalGoal.init(rawValue:))),
                servings: stored.servings,
                createdAt: stored.configurationCreatedAt
            ),
            days: stored.days
                .sorted { $0.dayIndex < $1.dayIndex }
                .map { day in
                    PlanDay(
                        dayIndex: day.dayIndex,
                        meals: day.meals
                            .compactMap(domainMeal(from:))
                            .sorted { $0.slot.sortOrder < $1.slot.sortOrder }
                    )
                },
            shoppingList: stored.shoppingList.map { line in
                ShoppingLine(
                    productID: line.productID,
                    productName: line.productNameSnapshot,
                    packages: line.packages,
                    requiredQuantity: line.requiredQuantity,
                    purchasedQuantity: line.purchasedQuantity,
                    unit: line.quantityUnit,
                    cost: line.cost
                )
            }
            .sorted { ($0.cost, $0.productName) > ($1.cost, $1.productName) }
        )
    }

    private static func domainMeal(from stored: StoredMeal) -> PlannedMeal? {
        guard let slot = MealSlot(rawValue: stored.slotRaw) else { return nil }

        return PlannedMeal(
            slot: slot,
            name: stored.name,
            prepTimeMinutes: stored.prepTimeMinutes,
            servings: stored.servings,
            ingredients: stored.ingredients.sorted { $0.position < $1.position }.map { ingredient in
                MealIngredient(
                    productID: ingredient.productID,
                    productName: ingredient.productNameSnapshot,
                    quantity: ingredient.quantityValue,
                    unit: ingredient.quantityUnit,
                    costShare: ingredient.costShare
                )
            },
            pantryItems: stored.pantryItemsRaw.compactMap(PantryStaple.init(rawValue:)),
            recipe: Recipe(
                ingredientLines: stored.recipeIngredientLines,
                steps: stored.recipeSteps
            )
        )
    }
}

private extension MealSlot {
    /// SwiftData returns relationship arrays unordered, so meals need an
    /// explicit meal-of-day ordering rather than whatever comes back.
    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        }
    }
}
