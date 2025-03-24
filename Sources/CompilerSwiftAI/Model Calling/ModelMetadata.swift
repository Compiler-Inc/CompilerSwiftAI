//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine

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
    let temperature: Double?
    let maxTokens: Int?

    init(provider: ModelProvider,
         capabilities: [ModelCapability] = [.chat],
         model: Model,
         temperature: Double? = nil,
         maxTokens: Int? = nil)
    {
        self.provider = provider
        self.capabilities = capabilities
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    // Convenience initializers for each provider's Models
    static func openAI(_ model: OpenAIModel, temperature: Double? = nil, maxTokens: Int? = nil) -> ModelMetadata {
        ModelMetadata(provider: .openai, model: model.rawValue, temperature: temperature, maxTokens: maxTokens)
    }

    static func anthropic(_ model: AnthropicModel, temperature: Double? = nil, maxTokens: Int? = nil) -> ModelMetadata {
        ModelMetadata(provider: .anthropic, model: model.rawValue, temperature: temperature, maxTokens: maxTokens)
    }

    static func perplexity(_ model: PerplexityModel, temperature: Double? = nil, maxTokens: Int? = nil) -> ModelMetadata {
        ModelMetadata(provider: .perplexity, model: model.rawValue, temperature: temperature, maxTokens: maxTokens)
    }

    static func deepseek(_ model: DeepSeekModel, temperature: Double? = nil, maxTokens: Int? = nil) -> ModelMetadata {
        ModelMetadata(provider: .deepseek, model: model.rawValue, temperature: temperature, maxTokens: maxTokens)
    }

    static func google(_ model: GeminiModel, temperature: Double? = nil, maxTokens: Int? = nil) -> ModelMetadata {
        ModelMetadata(provider: .google, model: model.rawValue, temperature: temperature, maxTokens: maxTokens)
    }

    static func == (lhs: ModelMetadata, rhs: ModelMetadata) -> Bool {
        lhs.model == rhs.model
            && lhs.provider == rhs.provider
            && lhs.capabilities == rhs.capabilities
            && lhs.temperature == rhs.temperature
            && lhs.maxTokens == rhs.maxTokens
    }
}
