//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

/// Represents a message in the chat history, matching OpenAI/Anthropic's format
public struct APIMessage: Codable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

/// Request format for model calls, matching the backend API contract
public struct ModelCallRequest: Codable {
    public let provider: ModelProvider
    public let model: ModelID
    public let messages: [APIMessage]
    
    public init(using metadata: ModelMetadata, messages: [Message]) {
        self.provider = metadata.provider
        self.model = metadata.id
        
        Logger.modelCalls.debug("Converting \(messages.count) messages to API format")
        let apiMessages = messages.map { message in
            APIMessage(role: message.role.rawValue, content: message.content)
        }
        self.messages = apiMessages
    }
}
