//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

/// Represents a message in the chat history, matching OpenAI/Anthropic's format
struct APIMessage: Codable {
    let role: String
    let content: String
}

/// Request format for model calls, matching the backend API contract
struct ModelCallRequest: Codable {
    let provider: ModelProvider
    let model: ModelID
    let messages: [APIMessage]
    
    init(using metadata: ModelMetadata, messages: [Message]) {
        self.provider = metadata.provider
        self.model = metadata.id
        
        Logger.modelCalls.debug("Converting \(messages.count) messages to API format")
        let apiMessages = messages.map { message in
            APIMessage(role: message.role.rawValue, content: message.content)
        }
        self.messages = apiMessages
    }
}

struct ModelCallResponse: Codable, Sendable {
    let role: String
    let content: String
}
