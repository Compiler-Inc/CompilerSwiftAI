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
    
    enum ContentType: String, Codable {
        case text
        case image
    }
    
    struct Content: Codable, Equatable {
        let type: ContentType
        let content: ContentData
        
        enum ContentData: Codable, Equatable {
            case text(String)
            case image(ImageContent)
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .text(let text):
                    try container.encode(text)
                case .image(let imageContent):
                    try container.encode(imageContent)
                }
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let text = try? container.decode(String.self) {
                    self = .text(text)
                } else if let imageContent = try? container.decode(ImageContent.self) {
                    self = .image(imageContent)
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode ContentData")
                }
            }
        }
    }
    
    struct ImageContent: Codable, Equatable {
        let base64Data: String
        let mimeType: MimeType
        
        enum MimeType: String, Codable {
            case jpeg = "image/jpeg"
            case png = "image/png"
            case gif = "image/gif"
            case webp = "image/webp"
        }
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
        self.id = UUID()  // Generate new UUID on decode since we don't send it
        self.role = try container.decode(Role.self, forKey: .role)
        self.content = try container.decode(String.self, forKey: .content)
        self.state = .complete  // Default to complete state when decoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(content, forKey: .content)
    }
}

// Convenience extensions for creating messages
extension Message.Content {
    static func text(_ text: String) -> Self {
        Message.Content(type: .text, content: .text(text))
    }
    
    static func image(base64: String, mimeType: Message.ImageContent.MimeType) -> Self {
        let imageContent = Message.ImageContent(base64Data: base64, mimeType: mimeType)
        return Message.Content(type: .image, content: .image(imageContent))
    }
}

