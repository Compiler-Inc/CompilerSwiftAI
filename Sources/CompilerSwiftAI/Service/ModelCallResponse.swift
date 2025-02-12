//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct ModelCallResponse<Response: Codable & Sendable>: Codable {
    public let role: String
    public let content: String
    public let refusal: String?
    public let response: Response?
    
    public init(role: String, content: String, refusal: String?, response: Response?) {
        self.role = role
        self.content = content
        self.refusal = refusal
        self.response = response
    }
}
