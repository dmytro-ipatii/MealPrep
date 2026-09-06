//
//  ChatCompletionsClient.swift
//  MealPrep
//
//  Created by Dmytro Ipatii on 06/09/2026.
//

import OpenAI

/// The one MacPaw entry point `MacPawLLMClient` actually needs, extracted so
/// tests can fake it without conforming to the much larger `OpenAIProtocol`
/// or touching the network.
protocol ChatCompletionsClient: Sendable {
    func chats(query: ChatQuery) async throws -> ChatResult
}

extension OpenAI: ChatCompletionsClient {}
