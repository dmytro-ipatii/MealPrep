//
//  MealPlanLLMClient.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


/// The pipeline depends on this protocol, never on MacPaw's `OpenAI` types
/// directly — `MacPawLLMClient` is the only file allowed to import `OpenAI`
/// outside of the wire-format schema types themselves.
protocol MealPlanLLMClient: Sendable {
    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton
    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton
    func generateRecipes(_ request: RecipeRequest) async throws -> DayRecipes
}