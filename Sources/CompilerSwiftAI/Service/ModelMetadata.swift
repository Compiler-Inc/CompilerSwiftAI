//  Copyright © 2025 Compiler, Inc. All rights reserved.

public typealias ModelID = String

public struct ModelMetadata: Codable {
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
} 
