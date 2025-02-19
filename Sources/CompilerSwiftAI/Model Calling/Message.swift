//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Combine
import SwiftUI

struct Message: Codable, Sendable, Identifiable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    var state: MessageState
    
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
            case .streaming(let partial): return partial
            }
        }
    }
    
    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.state = .complete
    }
    
    init(id: UUID = UUID(), role: Role, content: String, state: MessageState = .complete) {
        self.id = id
        self.role = role
        self.content = content
        self.state = state
    }
}

