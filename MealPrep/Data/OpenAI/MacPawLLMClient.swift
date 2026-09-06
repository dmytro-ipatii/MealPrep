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

    func generatePlanSkeleton(_ request: PlanSkeletonRequest) async throws -> PlanSkeleton {
        let query = ChatQuery(
            messages: [
                .system(.init(content: .textContent(PlanSkeletonPromptBuilder.systemPrompt()))),
                .user(.init(content: .string(PlanSkeletonPromptBuilder.userPrompt(for: request)))),
            ],
            model: model,
            responseFormat: .jsonSchema(
                .init(
                    name: "meal_plan_skeleton",
                    description: "A structural meal plan skeleton: meals, product IDs, and quantities, with no recipe text.",
                    schema: .derivedJsonSchema(PlanSkeleton.self),
                    strict: true
                )
            ),
            temperature: 0.2
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

        return try JSONDecoder().decode(PlanSkeleton.self, from: data)
    }
}
