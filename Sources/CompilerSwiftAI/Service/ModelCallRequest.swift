//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct ModelCallRequest: Codable {
    public let systemPrompt: String
    public let userPrompt: String
    public let provider: ModelProvider
    public let model: ModelID
    
    public init(systemPrompt: String, userPrompt: String, provider: ModelProvider, model: ModelID) {
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.provider = provider
        self.model = model
    }
}
