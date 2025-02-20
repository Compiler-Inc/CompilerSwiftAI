//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

public typealias Model = String

enum ModelCapability: String, Codable, Sendable, Equatable {
    case chat
    case audio
    case image
    case video
}

struct ModelMetadata: Codable, Sendable, Equatable {
    let model: Model
    let provider: ModelProvider
    let capabilities: [ModelCapability]
    
    init(provider: ModelProvider, capabilities: [ModelCapability] = [.chat], model: Model) {
        self.provider = provider
        self.capabilities = capabilities
        self.model = model
    }
    
    // Convenience initializers for each provider's Models
    static func openAI(_ model: OpenAIModel) -> ModelMetadata {
        ModelMetadata(provider: .openai, model: model.rawValue)
    }
    
    static func anthropic(_ model: AnthropicModel) -> ModelMetadata {
        ModelMetadata(provider: .anthropic, model: model.rawValue)
    }
    
    static func perplexity(_ model: PerplexityModel) -> ModelMetadata {
        ModelMetadata(provider: .perplexity, model: model.rawValue)
    }
    
    static func deepseek(_ model: DeepSeekModel) -> ModelMetadata {
        ModelMetadata(provider: .deepseek, model: model.rawValue)
    }
    
    static func == (lhs: ModelMetadata, rhs: ModelMetadata) -> Bool {
        lhs.model == rhs.model
        && lhs.provider == rhs.provider
        && lhs.capabilities == rhs.capabilities
    }
}

