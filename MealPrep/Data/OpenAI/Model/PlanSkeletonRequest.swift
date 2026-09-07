//
//  PlanSkeletonRequest.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


/// Everything Pass A needs to know to generate a plan skeleton, already
/// dietary-filtered, ranked, and narrowed to a shortlist by the deterministic
/// pipeline. The model only ever sees `candidates` — it cannot select a
/// product outside this list because it was never told about one.
struct PlanSkeletonRequest: Sendable {
    let dayCount: Int
    let startingDayIndex: Int
    let configuration: MealPlanConfiguration
    let candidates: [Product]

    init(
        dayCount: Int,
        startingDayIndex: Int = 0,
        configuration: MealPlanConfiguration,
        candidates: [Product]
    ) {
        self.dayCount = dayCount
        self.startingDayIndex = startingDayIndex
        self.configuration = configuration
        self.candidates = candidates
    }
}