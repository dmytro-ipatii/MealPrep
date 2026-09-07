//
//  RecipeRequest.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


/// One day of an already-validated skeleton, plus the products it references,
/// so the prompt can name them. Pass B writes prose for exactly this day.
struct RecipeRequest: Sendable {
    let day: PlanSkeleton.Day
    let products: [Product]
    let configuration: MealPlanConfiguration
}
