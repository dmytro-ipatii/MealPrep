//
//  PlanRepairRequest.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


/// A repair round: the plan that failed, plus exactly what is wrong with it.
/// The model is asked for a *minimal edit*, never a regeneration — a fresh
/// plan would discard the parts that already validated.
struct PlanRepairRequest: Sendable {
    let skeleton: PlanSkeleton
    let violations: [PlanViolation]
    let configuration: MealPlanConfiguration
    let candidates: [Product]
    let skuLimit: Int
}