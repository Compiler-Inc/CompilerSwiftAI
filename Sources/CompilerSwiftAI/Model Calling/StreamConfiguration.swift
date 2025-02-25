//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

/// Configuration for streaming chat sessions
public struct StreamConfiguration: Sendable {
    // Internal access to metadata
    internal let metadata: ModelMetadata
    
    // Internal init for SDK use
    internal init(metadata: ModelMetadata) {
        self.metadata = metadata
    }
    
    /// Create a streaming configuration with raw values
    public init(
        provider: ModelProvider,
        model: Model,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) {
        self.metadata = ModelMetadata(
            provider: provider,
            capabilities: [.chat],
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
    }
}

// MARK: - Public Factory Methods
public extension StreamConfiguration {
    /// Create an OpenAI streaming configuration
    /// - Parameters:
    ///   - model: The OpenAI model to use
    ///   - temperature: Optional temperature parameter (0.0 - 1.0)
    ///   - maxTokens: Optional maximum tokens to generate
    static func openAI(
        _ model: OpenAIModel,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) -> StreamConfiguration {
        .init(metadata: ModelMetadata(
            provider: .openai,
            model: model.rawValue,
            temperature: temperature,
            maxTokens: maxTokens
        ))
    }
    
    /// Create an Anthropic streaming configuration
    /// - Parameters:
    ///   - model: The Anthropic model to use
    ///   - temperature: Optional temperature parameter (0.0 - 1.0)
    ///   - maxTokens: Optional maximum tokens to generate
    static func anthropic(
        _ model: AnthropicModel,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) -> StreamConfiguration {
        .init(metadata: ModelMetadata(
            provider: .anthropic,
            model: model.rawValue,
            temperature: temperature,
            maxTokens: maxTokens
        ))
    }
    
    /// Create a Perplexity streaming configuration
    /// - Parameters:
    ///   - model: The Perplexity model to use
    ///   - temperature: Optional temperature parameter (0.0 - 1.0)
    ///   - maxTokens: Optional maximum tokens to generate
    static func perplexity(
        _ model: PerplexityModel,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) -> StreamConfiguration {
        .init(metadata: ModelMetadata(
            provider: .perplexity,
            model: model.rawValue,
            temperature: temperature,
            maxTokens: maxTokens
        ))
    }
    
    /// Create a DeepSeek streaming configuration
    /// - Parameters:
    ///   - model: The DeepSeek model to use
    ///   - temperature: Optional temperature parameter (0.0 - 1.0)
    ///   - maxTokens: Optional maximum tokens to generate
    static func deepseek(
        _ model: DeepSeekModel,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) -> StreamConfiguration {
        .init(metadata: ModelMetadata(
            provider: .deepseek,
            model: model.rawValue,
            temperature: temperature,
            maxTokens: maxTokens
        ))
    }
    
    /// Create a Google streaming configuration
    /// - Parameters:
    ///   - model: The Gemini model to use
    ///   - temperature: Optional temperature parameter (0.0 - 1.0)
    ///   - maxTokens: Optional maximum tokens to generate
    static func google(
        _ model: GeminiModel,
        temperature: Float? = nil,
        maxTokens: Int? = nil
    ) -> StreamConfiguration {
        .init(metadata: ModelMetadata(
            provider: .google,
            model: model.rawValue,
            temperature: temperature,
            maxTokens: maxTokens
        ))
    }
} 
