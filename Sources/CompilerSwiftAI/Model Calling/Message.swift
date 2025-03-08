//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

struct Message: Sendable, Equatable {
    enum Role: String, Sendable {
        case system
        case user
        case assistant
    }

    let id: String
    let role: Role
    let content: String

    init(id: String, role: Message.Role, content: String) {
        self.id = id
        self.role = role
        self.content = content
    }
    
    init(dto: MessageDTO) {
        self.id = dto.id
        self.role = .init(rawValue: dto.role)!
        self.content = dto.content
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
