//  Copyright © 2025 Compiler, Inc. All rights reserved.

/// AI Models supported by Compiler
enum ModelProvider: String, Codable, Sendable, Equatable {
    case OpenAI
    case Anthropic
    case Perplexity
    case DeepSeek
}

enum OpenAIModel: String, Codable {
    case gpt4o = "chatgpt-4o-latest"
    case gpt4oMini = "gpt-4o-mini"
}

enum AnthropicModel: String, Codable {
    case claudeSonnet = "claude-3-5-sonnet-latest"
    case claudeHaiku = "claude-3-5-haiku-latest"
    case claudeOpus = "claude-3-5-opus-latest"
}

enum PerplexityModel: String, Codable {
    case sonarReasoning = "sonar-reasoning"
    case sonarPro = "sonar-pro"
    case sonar = "sonar"
} 
enum DeepSeekModel: String, Codable {
    case chat = "deepseek-chat"
    case reasoner = "deepseek-reasoner"
}
