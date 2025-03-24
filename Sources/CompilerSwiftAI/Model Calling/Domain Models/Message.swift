//  Copyright 2025 Compiler, Inc. All rights reserved.

import Combine
import Foundation

public struct Message: Sendable, Equatable {
    public enum Role: String, Sendable {
        case system
        case user
        case assistant
    }
    
    public enum ContentType: String, Sendable {
        case text
        case imageUrl = "image_url"
    }
    
    public enum Content: Sendable, Equatable {
        case text(String)
        case image(String)
        case toolCall(ToolCallDelta)
        case toolCallResult(String)
        
        var type: ContentType {
            switch self {
            case .text: return .text
            case .image: return .imageUrl
            case .toolCall: return .text
            case .toolCallResult: return .text
            }
        }
        
        var value: String {
            switch self {
            case .text(let text): return text
            case .image(let url): return url
            case .toolCall(let toolCall): return "Function call: \(toolCall.function?.name ?? "")"
            case .toolCallResult(let result): return result
            }
        }
    }
    
    public let id: String
    public let role: Role
    public let content: [Content]

    public init(id: String, role: Message.Role, content: [Content]) {
        self.id = id
        self.role = role
        self.content = content
    }
    
    public init(role: Message.Role, content: [Content]) {
        self.init(id: UUID().uuidString, role: role, content: content)
    }
    
    // Single content convenience initializer
    public init(role: Message.Role, content: Content) {
        self.init(role: role, content: [content])
    }
    
    init(dto: MessageDTO) {
        self.id = dto.id
        self.role = Role(rawValue: dto.role) ?? .user
        self.content = dto.content.compactMap { content in
            if let text = content.text {
                return .text(text)
            } else if let imageUrl = content.imageUrl {
                return .image(imageUrl.url)
            }
            return nil
        }
    }
    
    /// Convert this Message to a MessageDTO
    func toDTO() -> MessageDTO {
        MessageDTO(message: self)
    }
}

extension Message {
    static func systemMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .system, content: [.text(content)])
    }
    
    static func userMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .user, content: [.text(content)])
    }
    
    static func assistantMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .assistant, content: [.text(content)])
    }
    
    static func systemMessage(text: String) -> Message {
        .init(role: .system, content: .text(text))
    }
    
    static func userMessage(text: String) -> Message {
        .init(role: .user, content: .text(text))
    }
    
    static func userMessage(imageUrl: String) -> Message {
        .init(role: .user, content: .image(imageUrl))
    }
    
    static func assistantMessage(text: String) -> Message {
        .init(role: .assistant, content: .text(text))
    }
}
