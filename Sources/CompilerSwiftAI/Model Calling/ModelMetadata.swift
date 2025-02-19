//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

public typealias ModelID = String

enum ModelCapability: String, Codable, Sendable, Equatable {
    case chat
    case audio
    case image
    case video
}

struct ModelMetadata: Codable, Sendable, Equatable {
    let modelID: ModelID
    let provider: ModelProvider
    let capabilities: [ModelCapability]
    
    init(provider: ModelProvider, capabilities: [ModelCapability] = [.chat], modelID: ModelID) {
        self.provider = provider
        self.capabilities = capabilities
        self.modelID = modelID
    }
    
    // Convenience initializers for each provider's Models
    static func openAI(_ model: OpenAIModel) -> ModelMetadata {
        ModelMetadata(provider: .OpenAI, modelID: model.rawValue)
    }
    
    static func anthropic(_ model: AnthropicModel) -> ModelMetadata {
        ModelMetadata(provider: .Anthropic, modelID: model.rawValue)
    }
    
    static func perplexity(_ model: PerplexityModel) -> ModelMetadata {
        ModelMetadata(provider: .Perplexity, modelID: model.rawValue)
    }
    
    static func deepseek(_ model: DeepSeekModel) -> ModelMetadata {
        ModelMetadata(provider: .DeepSeek, modelID: model.rawValue)
    }
    
    static func == (lhs: ModelMetadata, rhs: ModelMetadata) -> Bool {
        lhs.modelID == rhs.modelID
        && lhs.provider == rhs.provider
        && lhs.capabilities == rhs.capabilities
    }
}

