//
//  MacPawLLMClientTests.swift
//  MealPrepTests
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import Foundation
import OpenAI
import Testing
@testable import MealPrep

struct MacPawLLMClientTests {

    @Test func decodesAValidStructuredResponseIntoAPlanSkeleton() async throws {
        let skeletonJSON = """
        {"days":[{"dayIndex":0,"meals":[{"slot":"breakfast","name":"Oats","prepTimeMinutes":5,"ingredients":[{"productID":"p1","grams":100}],"pantryItems":[]}]}]}
        """
        let fake = FakeChatCompletionsClient(result: .success(.stub(content: skeletonJSON)))
        let client = MacPawLLMClient(client: fake)

        let skeleton = try await client.generatePlanSkeleton(.stub())

        #expect(skeleton.days.count == 1)
        #expect(skeleton.days[0].meals[0].name == "Oats")
        #expect(skeleton.days[0].meals[0].ingredients[0].productID == "p1")
    }

    @Test func sendsStrictJSONSchemaResponseFormat() async throws {
        let fake = FakeChatCompletionsClient(
            result: .success(.stub(content: "{\"days\":[{\"dayIndex\":0,\"meals\":[]}]}"))
        )
        let client = MacPawLLMClient(client: fake)

        _ = try? await client.generatePlanSkeleton(.stub())

        let sentQuery = try #require(fake.capturedQuery)

        // `StructuredOutputConfigurationOptions`'s stored properties are
        // package-internal, and its `==` goes through a schema-derivation
        // round trip that isn't reliable to compare against a freshly built
        // expected value — so assert on the actual wire JSON instead.
        let encoded = String(decoding: try JSONEncoder().encode(sentQuery), as: UTF8.self)

        #expect(encoded.contains("\"type\":\"json_schema\""))
        #expect(encoded.contains("\"name\":\"meal_plan_skeleton\""))
        #expect(encoded.contains("\"strict\":true"))
        #expect(encoded.contains("\"days\""))
    }

    @Test func refusalSurfacesAsALLMErrorNotADecodeFailure() async {
        let fake = FakeChatCompletionsClient(result: .success(.stub(content: nil, refusal: "I can't help with that.")))
        let client = MacPawLLMClient(client: fake)

        await #expect(throws: MealPlanLLMError.refusal("I can't help with that.")) {
            try await client.generatePlanSkeleton(.stub())
        }
    }

    @Test func emptyChoicesThrowsEmptyResponse() async {
        let fake = FakeChatCompletionsClient(result: .success(.stubEmptyChoices()))
        let client = MacPawLLMClient(client: fake)

        await #expect(throws: MealPlanLLMError.emptyResponse) {
            try await client.generatePlanSkeleton(.stub())
        }
    }

    @Test func missingContentAndNoRefusalThrowsEmptyResponse() async {
        let fake = FakeChatCompletionsClient(result: .success(.stub(content: nil, refusal: nil)))
        let client = MacPawLLMClient(client: fake)

        await #expect(throws: MealPlanLLMError.emptyResponse) {
            try await client.generatePlanSkeleton(.stub())
        }
    }

    @Test func networkErrorPropagates() async {
        struct NetworkFailure: Error, Equatable {}
        let fake = FakeChatCompletionsClient(result: .failure(NetworkFailure()))
        let client = MacPawLLMClient(client: fake)

        await #expect(throws: NetworkFailure.self) {
            try await client.generatePlanSkeleton(.stub())
        }
    }
}

private final class FakeChatCompletionsClient: ChatCompletionsClient, @unchecked Sendable {
    private let result: Result<ChatResult, Error>
    private(set) var capturedQuery: ChatQuery?

    init(result: Result<ChatResult, Error>) {
        self.result = result
    }

    func chats(query: ChatQuery) async throws -> ChatResult {
        capturedQuery = query
        return try result.get()
    }
}

private extension ChatResult {
    /// `ChatResult`'s member types have no public memberwise initializer, so
    /// the stub is built the same way the real client receives one: decoded
    /// from JSON.
    static func stub(content: String?, refusal: String? = nil) -> ChatResult {
        stub(choicesJSON: """
        [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": \(jsonString(content)),
                    "refusal": \(jsonString(refusal))
                },
                "finish_reason": "stop"
            }
        ]
        """)
    }

    static func stubEmptyChoices() -> ChatResult {
        stub(choicesJSON: "[]")
    }

    private static func stub(choicesJSON: String) -> ChatResult {
        let json = """
        {
            "id": "test-id",
            "object": "chat.completion",
            "created": 0,
            "model": "gpt-4o",
            "choices": \(choicesJSON)
        }
        """
        return try! JSONDecoder().decode(ChatResult.self, from: Data(json.utf8))
    }

    private static func jsonString(_ value: String?) -> String {
        guard let value else { return "null" }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

private extension PlanSkeletonRequest {
    static func stub() -> PlanSkeletonRequest {
        PlanSkeletonRequest(
            dayCount: 1,
            configuration: MealPlanConfiguration(
                weeklyBudget: Decimal(70),
                currencyCode: "EUR",
                dietaryNeeds: [],
                goals: [],
                servings: 1,
                createdAt: Date()
            ),
            candidates: [
                Product(
                    id: "p1",
                    name: "Oats",
                    departmentID: "colazione",
                    categoryID: "en:breakfast-cereals",
                    baseQuantity: .mass(grams: 500),
                    price: Decimal(1.5),
                    nutrition: NutritionFacts(
                        energyKcal: 100, proteins: 5, carbohydrates: 10, sugars: 2,
                        fat: 3, saturatedFat: 1, fiber: 1, salt: 0.5
                    ),
                    labelIDs: [],
                    allergenIDs: []
                )
            ]
        )
    }
}
