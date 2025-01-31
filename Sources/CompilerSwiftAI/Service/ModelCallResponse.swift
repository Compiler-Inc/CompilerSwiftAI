//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct ModelCallResponse: Codable {
    public let role: String
    public let content: String
    public let refusal: String?
    
    public init(role: String, content: String, refusal: String?) {
        self.role = role
        self.content = content
        self.refusal = refusal
    }
}
