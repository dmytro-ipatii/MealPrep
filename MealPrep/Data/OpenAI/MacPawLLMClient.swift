//
//  MacPawLLMClient.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import OpenAI

/// The only file (besides `PlanSkeleton`'s wire-format types) allowed to
/// import `OpenAI` directly. Everything else in the pipeline talks to
/// `MealPlanLLMClient`.
struct MacPawLLMClient: MealPlanLLMClient {

    private let client: ChatCompletionsClient
    private let model: Model

    init(client: ChatCompletionsClient, model: Model = "gpt-4o") {
        self.client = client
        self.model = model
    }

    /// Pass A is constraint satisfaction, not creativity — keep it cold.
    private static let planningTemperature = 0.2
    /// Pass B is prose. Seven near-identical days would read as a bug.
    private static let recipeTemperature = 0.7

    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton {
        try await requestStructuredOutput(
            systemPrompt: PlanSkeletonPromptBuilder.systemPrompt(),
            userPrompt: PlanSkeletonPromptBuilder.userPrompt(for: request),
            schemaName: "meal_plan_skeleton",
            schemaDescription: "A structural meal plan skeleton: meals, product IDs, and quantities, with no recipe text.",
            schemaType: PlanSkeleton.self,
            temperature: Self.planningTemperature
        )
    }

    func repairPlanSkeleton(_ request: PlanRepairRequest) async throws -> PlanSkeleton {
        try await requestStructuredOutput(
            systemPrompt: PlanSkeletonPromptBuilder.systemPrompt(),
            userPrompt: PlanSkeletonPromptBuilder.repairPrompt(for: request),
            schemaName: "meal_plan_skeleton",
            schemaDescription: "A minimally edited meal plan skeleton that fixes the reported violations.",
            schemaType: PlanSkeleton.self,
            temperature: Self.planningTemperature
        )
    }

    func generateRecipes(_ request: RecipeRequest) async throws -> DayRecipes {
        try await requestStructuredOutput(
            systemPrompt: RecipePromptBuilder.systemPrompt(),
            userPrompt: RecipePromptBuilder.userPrompt(for: request),
            schemaName: "day_recipes",
            schemaDescription: "Recipe prose for one day: a name, readable ingredient lines, and ordered steps per meal.",
            schemaType: DayRecipes.self,
            temperature: Self.recipeTemperature
        )
    }

    private func requestStructuredOutput<Output: JSONSchemaConvertible>(
        systemPrompt: String,
        userPrompt: String,
        schemaName: String,
        schemaDescription: String,
        schemaType: Output.Type,
        temperature: Double
    ) async throws -> Output {
        let query = ChatQuery(
            messages: [
                .system(.init(content: .textContent(systemPrompt))),
                .user(.init(content: .string(userPrompt))),
            ],
            model: model,
            responseFormat: .jsonSchema(
                .init(
                    name: schemaName,
                    description: schemaDescription,
                    schema: .derivedJsonSchema(schemaType),
                    strict: true
                )
            ),
            temperature: temperature
        )

        let result = try await client.chats(query: query)

        guard let message = result.choices.first?.message else {
            throw MealPlanLLMError.emptyResponse
        }

        if let refusal = message.refusal {
            throw MealPlanLLMError.refusal(refusal)
        }

        guard let content = message.content, let data = content.data(using: .utf8) else {
            throw MealPlanLLMError.emptyResponse
        }

        return try JSONDecoder().decode(Output.self, from: data)
    }
}
