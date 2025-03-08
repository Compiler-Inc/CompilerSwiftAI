//
//  MessageDTO.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import Foundation

struct MessageDTO: Codable, Sendable {
    let id: String
    let role: String
    let content: String
    
    init(message: Message) {
        self.id = message.id
        self.role = message.role.rawValue
        self.content = message.content
    }
    
    func toMessage() -> Message {
        Message(
            id: id,
            role: Message.Role(rawValue: role) ?? .user,
            content: content
        )
    }
}
