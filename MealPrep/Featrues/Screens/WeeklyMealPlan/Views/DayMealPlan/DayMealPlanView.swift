//
//  DayMealPlanView.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import SwiftUI

struct DayMealPlanView: View {
    var weekDay: WeekDay
    var day: PlanDay?

    @State private var selectedSlot: MealSlot = .breakfast

    private var meal: PlannedMeal? {
        day?.meals.first { $0.slot == selectedSlot } ?? day?.meals.first
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpace.xl.value) {

                Text(weekDay.name)
                    .modifier(DayMealPlanSectionTitleViewModifier(font: .dsHeadline))

                slotPicker

                if let meal {
                    MealDetailsView(meal: meal)

                    ingredientsSection(for: meal)

                    recipeSection(for: meal)
                } else {
                    Text("No meals for this day.")
                        .font(.dsBody)
                        .foregroundStyle(DSColor.textSecondary.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DSSpace.xl.value)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(
                topLeading: DSCornerRadius.xl.value,
                topTrailing: DSCornerRadius.xl.value,
            ))
            .fill(DSColor.backgroundPrimary.value)
        )
    }

    private var slotPicker: some View {
        HStack(spacing: DSSpace.xs.value) {
            ForEach(MealSlot.allCases, id: \.self) { slot in
                Button {
                    selectedSlot = slot
                } label: {

                    let isSelected = slot == selectedSlot
                    let background = isSelected ? DSColor.accent : DSColor.backgroundSecondary
                    let foreground = isSelected ? DSColor.textVibrantPrimary.value : DSColor.textSecondary.value

                    Text(slot.displayName)
                        .font(.dsFootnote)
                        .foregroundStyle(foreground)
                        .padding(.vertical, DSSpace.xs.value)
                        .frame(maxWidth: .infinity)
                        .dsBackground(color: background, radius: .full)

                }
                .buttonStyle(.plain)
            }
        }
    }

    private func ingredientsSection(for meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.xs.value) {
            Text("Ingredients")
                .modifier(DayMealPlanSectionTitleViewModifier(font: .dsFootnote))

            ForEach(meal.ingredients, id: \.productID) { ingredient in
                HStack(alignment: .top) {
                    Text(ingredient.productName)
                        .foregroundStyle(DSColor.textPrimary.value)

                    Spacer(minLength: DSSpace.sm.value)

                    Text("\(ingredient.quantity.toFormatedString()) \(ingredient.unit)")
                        .foregroundStyle(DSColor.textSecondary.value)
                }
                .font(.dsCaption)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recipeSection(for meal: PlannedMeal) -> some View {
        VStack(alignment: .leading, spacing: DSSpace.xs.value) {
            Text("Recipe")
                .modifier(DayMealPlanSectionTitleViewModifier(font: .dsFootnote))

            ForEach(Array(meal.recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: DSSpace.xs.value) {
                    Text("\(index + 1).")
                        .foregroundStyle(DSColor.textSecondary.value)

                    Text(step)
                        .foregroundStyle(DSColor.textPrimary.value)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.dsCaption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension MealSlot {
    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        }
    }
}

extension PantryStaple {
    var displayName: String {
        switch self {
        case .salt: "Salt"
        case .blackPepper: "Black pepper"
        case .oliveOil: "Olive oil"
        case .vegetableOil: "Vegetable oil"
        case .vinegar: "Vinegar"
        case .water: "Water"
        case .garlicPowder: "Garlic powder"
        case .driedHerbs: "Dried herbs"
        case .groundSpices: "Ground spices"
        case .bakingSoda: "Baking soda"
        }
    }
}

#Preview {
    VStack {
        DayMealPlanView(weekDay: .monday, day: MealPlan.preview.days.first)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DSColor.accent.value.ignoresSafeArea())
}
