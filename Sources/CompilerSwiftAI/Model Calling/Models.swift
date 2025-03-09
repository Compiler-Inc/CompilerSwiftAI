//  Copyright © 2025 Compiler, Inc. All rights reserved.

/// AI Models supported by Compiler
public enum ModelProvider: String, Codable, Sendable, Equatable {
    case openai
    case anthropic
    case perplexity
    case deepseek
    case google
}

public enum OpenAIModel: String, Codable {
    case gpt4o = "chatgpt-4o-latest"
    case gpt4oMini = "gpt-4o-mini"
    case o1
    case o1Mini = "o1-mini"
    case o3Mini = "o3-mini"
}

public enum GeminiModel: String, Codable {
    case flash = "gemini-2.0-flash"
    case flashLitePreview = "gemini-2.0-flash-lite-preview-02-05"
    case flash15 = "gemini-1.5-flash"
    case flash15_8b = "gemini-1.5-flash-8b"
    case pro15 = "gemini-1.5-pro"
    case textEmbedding = "text-embedding-004"
}

public enum AnthropicModel: String, Codable {
    case claudeSonnet = "claude-3-7-sonnet-latest"
    case claudeHaiku = "claude-3-5-haiku-latest"
    case claudeOpus = "claude-3-5-opus-latest"
}

public enum PerplexityModel: String, Codable {
    case sonarReasoning = "sonar-reasoning"
    case sonarPro = "sonar-pro"
    case sonar
}

public enum DeepSeekModel: String, Codable {
    case chat = "deepseek-chat"
    case reasoner = "deepseek-reasoner"
}
