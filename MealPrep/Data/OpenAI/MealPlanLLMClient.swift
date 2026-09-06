//
//  MealPlanLLMClient.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
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

enum MealPlanLLMError: Error, Sendable, Equatable {
    /// A structured-output refusal: the model declined to answer. Arrives
    /// with nil content and must not surface as a decode failure.
    case refusal(String)
    case emptyResponse
    case missingAPIKey
}

/// The pipeline depends on this protocol, never on MacPaw's `OpenAI` types
/// directly — `MacPawLLMClient` is the only file allowed to import `OpenAI`
/// outside of the wire-format schema types themselves.
protocol MealPlanLLMClient: Sendable {
    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton
    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton
}
