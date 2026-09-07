//
//  MealPlanLLMError.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 07/09/2026.
//


enum MealPlanLLMError: Error, Sendable, Equatable {
    /// A structured-output refusal: the model declined to answer. Arrives
    /// with nil content and must not surface as a decode failure.
    case refusal(String)
    case emptyResponse
    case missingAPIKey
}