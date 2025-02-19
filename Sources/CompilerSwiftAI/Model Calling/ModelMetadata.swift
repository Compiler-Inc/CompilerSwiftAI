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
        ModelMetadata(provider: .OpenAI, id: model.rawValue)
    }
    
    public static func anthropic(_ model: AnthropicModel) -> ModelMetadata {
        ModelMetadata(provider: .Anthropic, id: model.rawValue)
    }
    
    public static func perplexity(_ model: PerplexityModel) -> ModelMetadata {
        ModelMetadata(provider: .Perplexity, id: model.rawValue)
    }
    
    public static func deepseek(_ model: DeepSeekModel) -> ModelMetadata {
        ModelMetadata(provider: .DeepSeek, id: model.rawValue)
    }
    
    public static func == (lhs: ModelMetadata, rhs: ModelMetadata) -> Bool {
        lhs.id == rhs.id
        && lhs.provider == rhs.provider
        && lhs.capabilities == rhs.capabilities
    }
}

struct Message: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    var state: MessageState
    
    enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
    }
    
    enum MessageState: Codable, Sendable, Equatable {
        case complete
        case streaming(String)
        
        var isStreaming: Bool {
            if case .streaming = self { return true }
            return false
        }
        
        var currentContent: String {
            switch self {
            case .complete: return ""
            case .streaming(let partial): return partial
            }
        }
    }
    
    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.state = .complete
    }
    
    init(id: UUID = UUID(), role: Role, content: String, state: MessageState = .complete) {
        self.id = id
        self.role = role
        self.content = content
        self.state = state
    }
}

