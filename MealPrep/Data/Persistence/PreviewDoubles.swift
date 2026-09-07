//
//  PreviewDoubles.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

#if DEBUG
import Foundation

/// Stand-ins so SwiftUI previews never touch SwiftData or the network.
@MainActor
final class PreviewMealPlanRepository: MealPlanRepositoryProtocol {
    private var plan: MealPlan?

    init(plan: MealPlan? = nil) {
        self.plan = plan
    }

    func loadLatestPlan() -> MealPlan? { plan }
    func save(_ plan: MealPlan) throws { self.plan = plan }
    func deleteAll() throws { plan = nil }
}

struct PreviewMealPlanLLMClient: MealPlanLLMClient {
    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton {
        PlanSkeleton(days: [])
    }

    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton {
        request.skeleton
    }

    func generateRecipes(_ request: RecipeRequest) async throws -> DayRecipes {
        DayRecipes(meals: [])
    }
}
#endif
