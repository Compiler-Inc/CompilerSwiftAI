//  Copyright 2025 Compiler, Inc. All rights reserved.

import Foundation

public struct MessageDTO: Codable, Sendable {
    public enum ContentType: String, Codable, Sendable {
        case text = "text"
        case imageUrl = "image_url"
        case toolCall = "tool_call"
        case toolCallResult = "tool_call_result"
    }
    
    public struct Content: Codable, Sendable {
        let type: ContentType
        let text: String?
        let imageUrl: ImageUrl?
        let toolCall: ToolCallDelta?
        
        private enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
            case toolCall = "tool_call"
        }
    }
    
    public struct ImageUrl: Codable, Sendable {
        let url: String
    }
    
    public let id: String
    public let role: String
    public let content: [Content]
    
    public init(message: Message) {
        self.id = message.id
        self.role = message.role.rawValue
        self.content = message.content.map { content in
            switch content {
            case .text(let text):
                return Content(type: .text, text: text, imageUrl: nil, toolCall: nil)
            case .image(let url):
                return Content(type: .imageUrl, text: nil, imageUrl: ImageUrl(url: url), toolCall: nil)
            case .toolCall(let delta):
                return Content(type: .toolCall, text: nil, imageUrl: nil, toolCall: delta)
            case .toolCallResult(let result):
                return Content(type: .toolCallResult, text: result, imageUrl: nil, toolCall: nil)
            }
        }
    }
    
    public func toMessage() -> Message {
        Message(
            id: id,
            role: .init(rawValue: role) ?? .user,
            content: content.compactMap { content in
                switch content.type {
                case .text:
                    return content.text.map { .text($0) }
                case .imageUrl:
                    return content.imageUrl.map { .image($0.url) }
                case .toolCall:
                    return content.toolCall.map { .toolCall($0) }
                case .toolCallResult:
                    return content.text.map { .toolCallResult($0) }
                }
            }
        )
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.role, forKey: .role)
        try container.encode(self.content, forKey: .content)
    }
}
