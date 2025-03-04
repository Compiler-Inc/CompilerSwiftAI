//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

struct Message: Codable, Sendable, Identifiable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case role, content
    }

    enum Role: String, Codable, Sendable {
        case system
        case user
        case assistant
    }

    enum MessageState: Codable, Sendable, Equatable {
        case complete
        case streaming(String)

        var isStreaming: Bool {
            if case .streaming = self { return true }
            return false
        }

        var currentContent: String {
            switch self {
            case .complete: return ""
            case let .streaming(partial): return partial
            }
        }
    }

    let id: UUID
    let role: Role
    let content: String
    var state: MessageState

    init(id: UUID = UUID(), role: Message.Role, content: String, state: Message.MessageState = .complete) {
        self.id = id
        self.role = role
        self.content = content
        self.state = state
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID() // Generate new UUID on decode since we don't send it
        role = try container.decode(Role.self, forKey: .role)
        content = try container.decode(String.self, forKey: .content)
        state = .complete // Default to complete state when decoding
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}
