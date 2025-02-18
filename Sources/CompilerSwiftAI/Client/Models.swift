//  Copyright © 2025 Compiler, Inc. All rights reserved.

public enum ModelProvider: String, Codable, Sendable, Equatable {
    case openai
    case anthropic
    case perplexity
    case deepseek
}

public enum OpenAIModel: String, Codable {
    case gpt4o = "chatgpt-4o-latest"
    case gpt4oMini = "gpt-4o-mini"
}

public enum AnthropicModel: String, Codable {
    case claudeSonnet = "claude-3-5-sonnet-latest"
    case claudeHaiku = "claude-3-5-haiku-latest"
    case claudeOpus = "claude-3-5-opus-latest"
}

public enum PerplexityModel: String, Codable {
    case sonarReasoning = "sonar-reasoning"
    case sonarPro = "sonar-pro"
    case sonar = "sonar"
} 
public enum DeepSeekModel: String, Codable {
    case chat = "deepseek-chat"
    case reasoner = "deepseek-reasoner"
}
