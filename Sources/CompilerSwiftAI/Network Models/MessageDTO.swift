//
//  MessageDTO.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import Foundation

public struct MessageDTO: Codable, Sendable {
    public let id: String
    public let role: String
    public let content: String
    
    public init(message: Message) {
        self.id = message.id
        self.role = message.role.rawValue
        self.content = message.content
    }
    
    public func toMessage() -> Message {
        Message(
            id: id,
            role: Message.Role(rawValue: role) ?? .user,
            content: content
        )
    }
}
