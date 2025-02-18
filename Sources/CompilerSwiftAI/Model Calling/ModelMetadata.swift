//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

public typealias ModelID = String

public enum ModelCapability: String, Codable, Sendable, Equatable {
    case chat
    case audio
    case image
    case video
}

public struct ModelMetadata: Codable, Sendable, Equatable {
    public let id: ModelID
    public let provider: ModelProvider
    public let capabilities: [ModelCapability]
    
    public init(provider: ModelProvider, capabilities: [ModelCapability] = [.chat], id: ModelID) {
        self.provider = provider
        self.capabilities = capabilities
        self.id = id
    }
    
    // Convenience initializers for each provider's Models
    public static func openAI(_ model: OpenAIModel) -> ModelMetadata {
        ModelMetadata(provider: .openai, id: model.rawValue)
    }
    
    public static func anthropic(_ model: AnthropicModel) -> ModelMetadata {
        ModelMetadata(provider: .anthropic, id: model.rawValue)
    }
    
    public static func perplexity(_ model: PerplexityModel) -> ModelMetadata {
        ModelMetadata(provider: .perplexity, id: model.rawValue)
    }
    
    public static func deepseek(_ model: DeepSeekModel) -> ModelMetadata {
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

