//
//  MessageDTO.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import Foundation

public struct MessageDTO: Codable, Sendable {
    public enum ContentType: String, Codable, Sendable {
        case text = "text"
        case imageUrl = "image_url"
    }
    
    public struct Content: Codable, Sendable {
        let type: ContentType
        let text: String?
        let imageUrl: ImageUrl?
        
        private enum CodingKeys: String, CodingKey {
            case type
            case text
            case imageUrl = "image_url"
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
                return Content(type: .text, text: text, imageUrl: nil)
            case .image(let url):
                return Content(type: .imageUrl, text: nil, imageUrl: ImageUrl(url: url))
            }
        }
    }
    
    public func toMessage() -> Message {
        Message(
            id: id,
            role: .init(rawValue: role) ?? .user,
            content: content.compactMap { content in
                if let text = content.text {
                    return .text(text)
                } else if let imageUrl = content.imageUrl {
                    return .image(imageUrl.url)
                }
                return nil
            }
        )
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.role, forKey: .role)
        try container.encode(self.content, forKey: .content)
    }
}
