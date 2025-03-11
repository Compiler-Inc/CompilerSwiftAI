//  Copyright 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

public struct Message: Sendable, Equatable {
    public enum Role: String, Sendable {
        case system
        case user
        case assistant
    }

    public let id: String
    public let role: Role
    public let content: String

    public init(id: String, role: Message.Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
    
    init(dto: MessageDTO) {
        self.id = dto.id
        self.role = .init(rawValue: dto.role)!
        self.content = dto.content
    }
    
    /// Convert this Message to a MessageDTO
    func toDTO() -> MessageDTO {
        MessageDTO(message: self)
    }
}

extension Message {
    static func systemMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .system, content: content)
    }
    
    static func userMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .user, content: content)
    }
    
    static func assistantMessage(content: String) -> Message {
        .init(id: UUID().uuidString, role: .assistant, content: content)
    }
}
