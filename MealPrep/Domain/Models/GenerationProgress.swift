//
//  GenerationProgress.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

/// Generation is a 20-60 second multi-call operation. A bare spinner reads as
/// a hang, so every stage reports itself (app plan section 12).
///
/// `finished` carries the plan — an amendment to section 12, where the case is
/// bare. Without it the caller would need a second channel to receive the one
/// thing it actually asked for.
enum GenerationProgress: Sendable, Equatable {
    case loadingCatalog
    case filtering(candidateCount: Int)
    case checkingFeasibility
    case planning
    case validating(attempt: Int)
    case writingRecipes(completed: Int, total: Int)
    case finished(MealPlan)

    /// What to show the user while this stage runs.
    var message: String {
        switch self {
        case .loadingCatalog: "Reading the catalogue…"
        case .filtering: "Finding products that fit your needs…"
        case .checkingFeasibility: "Checking your budget…"
        case .planning: "Planning your week…"
        case .validating(let attempt): attempt <= 1 ? "Checking the plan…" : "Adjusting the plan…"
        case .writingRecipes(let completed, let total): "Writing recipes… \(completed) of \(total) days"
        case .finished: "Done"
        }
    }
}
