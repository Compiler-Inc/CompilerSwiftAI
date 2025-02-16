//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct ModelCallResponse: Codable, Sendable {
    public let role: String
    public let content: String
    
    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}
