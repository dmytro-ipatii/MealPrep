//
//  MealPlan+Preview.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

#if DEBUG
import Foundation

extension MealPlan {
    /// A small, realistic plan so previews render something recognisable.
    static let preview: MealPlan = {
        let names: [MealSlot: (String, Int)] = [
            .breakfast: ("Porridge with Banana and Walnuts", 8),
            .lunch: ("Chickpea and Tomato Salad", 15),
            .dinner: ("Baked Salmon with Rice and Broccoli", 35),
        ]

        let days = (0..<7).map { dayIndex in
            PlanDay(
                dayIndex: dayIndex,
                meals: MealSlot.allCases.map { slot in
                    let (name, prep) = names[slot] ?? ("Meal", 20)
                    return PlannedMeal(
                        slot: slot,
                        name: name,
                        prepTimeMinutes: prep,
                        servings: 1,
                        ingredients: [
                            MealIngredient(
                                productID: "oats",
                                productName: "Rolled Oats",
                                quantity: 60,
                                unit: "g",
                                costShare: Decimal(0.42)
                            ),
                            MealIngredient(
                                productID: "banana",
                                productName: "Bananas",
                                quantity: 120,
                                unit: "g",
                                costShare: Decimal(0.31)
                            ),
                        ],
                        pantryItems: [.salt, .oliveOil],
                        recipe: Recipe(
                            ingredientLines: ["60 g rolled oats", "1 banana", "salt"],
                            steps: [
                                "Bring 300 ml of water to a simmer.",
                                "Stir in the oats and cook for 5 minutes.",
                                "Slice the banana and fold it through.",
                            ]
                        )
                    )
                }
            )
        }

        return MealPlan(
            generatedAt: Date(),
            configuration: MealPlanConfiguration(
                weeklyBudget: 80,
                currencyCode: "EUR",
                dietaryNeeds: [.vegetarian],
                goals: [.highProtein],
                servings: 1,
                createdAt: Date()
            ),
            days: days,
            shoppingList: [
                ShoppingLine(
                    productID: "oats",
                    productName: "Rolled Oats",
                    packages: 1,
                    requiredQuantity: 420,
                    purchasedQuantity: 1000,
                    unit: "g",
                    cost: Decimal(2.49)
                ),
                ShoppingLine(
                    productID: "banana",
                    productName: "Bananas",
                    packages: 2,
                    requiredQuantity: 840,
                    purchasedQuantity: 1000,
                    unit: "g",
                    cost: Decimal(3.18)
                ),
            ]
        )
    }()
}
#endif
