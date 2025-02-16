//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation
import Combine
import SwiftUI

public typealias ModelID = String

public struct ModelMetadata: Codable, Sendable, Equatable {
    public let id: ModelID
    public let provider: ModelProvider
    public let capabilities: [ModelCapability]
    
    public init(provider: ModelProvider, capabilities: [ModelCapability] = [.chat], id: ModelID) {
        self.provider = provider
        self.capabilities = capabilities
        self.id = id
    }
    
    // Convenience initializers for each provider's models
    public static func openAI(_ model: OpenAIModels) -> ModelMetadata {
        ModelMetadata(provider: .openai, id: model.rawValue)
    }
    
    public static func anthropic(_ model: AnthropicModels) -> ModelMetadata {
        ModelMetadata(provider: .anthropic, id: model.rawValue)
    }
    
    public static func perplexity(_ model: PerplexityModels) -> ModelMetadata {
        ModelMetadata(provider: .perplexity, id: model.rawValue)
    }
    
    public static func deepseek(_ model: DeepSeekModels) -> ModelMetadata {
        ModelMetadata(provider: .deepseek, id: model.rawValue)
    }
    
    public static func == (lhs: ModelMetadata, rhs: ModelMetadata) -> Bool {
        lhs.id == rhs.id
        && lhs.provider == rhs.provider
        && lhs.capabilities == rhs.capabilities
    }
}

public struct Message: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let role: Role
    public let content: String
    public internal(set) var state: MessageState
    
    public enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
    }
    
    public enum MessageState: Codable, Sendable, Equatable {
        case complete
        case streaming(String)
        
        public var isStreaming: Bool {
            if case .streaming = self { return true }
            return false
        }
        
        public var currentContent: String {
            switch self {
            case .complete: return ""
            case .streaming(let partial): return partial
            }
        }
    }
    
    public init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.state = .complete
    }
    
    public init(id: UUID = UUID(), role: Role, content: String, state: MessageState = .complete) {
        self.id = id
        self.role = role
        self.content = content
        self.state = state
    }
}

/// A convenience type to help manage conversation history with LLMs
@available(macOS 14.0, iOS 17.0, *)
public actor ChatHistory {
    private var _messages: [Message]
    private var streamingMessageId: UUID?
    
    /// We'll store the active continuation if someone requests `messagesStream`.
    private var continuation: AsyncStream<[Message]>.Continuation?
    
    public var messages: [Message] {
        // Return all messages except those that are *still* streaming
        get async {
            _messages.filter { $0.state == .complete }
        }
    }
    
    /// A continuous stream of *all* messages, including .streaming states
    public var messagesStream: AsyncStream<[Message]> {
        AsyncStream { continuation in
            self.continuation = continuation
            // Immediately yield whatever we have
            continuation.yield(_messages)
        }
    }
    
    public init(systemPrompt: String) {
        self._messages = [Message(role: .system, content: systemPrompt)]
    }
    
    private func notifyMessageUpdate() {
        continuation?.yield(_messages)
    }
    
    public func addUserMessage(_ content: String) {
        _messages.append(Message(role: .user, content: content))
        notifyMessageUpdate()
    }
    
    public func addAssistantMessage(_ content: String) {
        _messages.append(Message(role: .assistant, content: content))
        notifyMessageUpdate()
    }
    
    /// Start a new streaming response from the assistant
    @discardableResult
    public func beginStreamingResponse() -> UUID {
        let id = UUID()
        let msg = Message(id: id, role: .assistant, content: "", state: .streaming(""))
        _messages.append(msg)
        streamingMessageId = id
        notifyMessageUpdate()
        return id
    }
    
    /// Update the partial text of the *current* streaming assistant message
    public func updateStreamingMessage(_ partial: String) {
        guard let id = streamingMessageId,
              let idx = _messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        let old = _messages[idx]
        _messages[idx] = Message(
            id: old.id,
            role: old.role,
            content: partial,
            state: .streaming(partial)
        )
        notifyMessageUpdate()
    }
    
    /// Mark the streaming message complete with final text
    public func completeStreamingMessage(_ finalContent: String) {
        guard let id = streamingMessageId,
              let idx = _messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        _messages[idx] = Message(
            id: id,
            role: .assistant,
            content: finalContent,
            state: .complete
        )
        streamingMessageId = nil
        notifyMessageUpdate()
    }
    
    public func clearHistory(keepingSystemPrompt: Bool = true) {
        streamingMessageId = nil
        if keepingSystemPrompt, let systemMessage = _messages.first, systemMessage.role == .system {
            _messages = [systemMessage]
        } else {
            _messages.removeAll()
        }
        notifyMessageUpdate()
    }
    
    deinit {
        continuation?.finish()
    }
}
