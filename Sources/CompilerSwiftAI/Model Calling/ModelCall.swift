//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

/// Represents a message in the chat history, matching OpenAI/Anthropic's format
struct APIMessage: Codable {
    let role: String
    let content: String
}

/// Base protocol for model call requests
protocol ModelCallRequestBase: Codable {
    var provider: ModelProvider { get }
    var model: String { get }
    var temperature: Float? { get }
    var maxTokens: Int? { get }
}

/// Request format for completion (non-streaming) model calls
struct CompletionRequest: ModelCallRequestBase {
    let provider: ModelProvider
    let model: String
    let systemPrompt: String?
    let userPrompt: String
    let temperature: Float?
    let maxTokens: Int?

    init(using metadata: ModelMetadata, systemPrompt: String? = nil, userPrompt: String) {
        provider = metadata.provider
        model = metadata.model
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        temperature = metadata.temperature
        maxTokens = metadata.maxTokens
    }
}

/// Request format for streaming model calls
struct StreamRequest: ModelCallRequestBase {
    let provider: ModelProvider
    let model: String
    let messages: [MessageDTO]
    let temperature: Float?
    let maxTokens: Int?

    init(using metadata: ModelMetadata, messages: [MessageDTO]) {
        provider = metadata.provider
        model = metadata.model
        self.messages = messages
        temperature = metadata.temperature
        maxTokens = metadata.maxTokens

        Logger.modelCalls.debug("Preparing stream request with \(messages.count) messages")
    }

    private enum CodingKeys: String, CodingKey {
        case provider, model, messages, temperature, maxTokens
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        if let temperature = temperature {
            try container.encode(temperature, forKey: .temperature)
        }
        if let maxTokens = maxTokens {
            try container.encode(maxTokens, forKey: .maxTokens)
        }
    }
}

/// Response format for completion calls
public struct CompletionResponse: Codable, Sendable {
    private struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }

        let message: Message
    }

    private let choices: [Choice]

    /// The generated text content
    public var content: String {
        choices.first?.message.content ?? ""
    }
}

/// Response format for streaming chunks
public struct StreamChunk: Codable, Sendable {
    private struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }

        let message: Message
    }

    private let choices: [Choice]

    /// The generated text content
    public var content: String {
        choices.first?.message.content ?? ""
    }
}
