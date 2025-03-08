//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

/// A convenience type to help manage conversation history with LLMs
actor ChatHistory: ObservableObject {
    @Published var messages: [Message] = []
    
    /// The current message that is being streamed.
    private var messageId: String?
    
    func addSystemPrompt(_ content: String) {
        messages.append(Message.systemMessage(content: content))
    }

    func addUserMessage(_ content: String) {
        messages.append(Message.userMessage(content: content))
    }

    /// Start a new streaming response from the assistant
    func beginStreamingResponse() {
        let msg = Message.assistantMessage(content: "")
        messages.append(msg)
        messageId = msg.id
    }

    /// Update the partial text of the *current* streaming assistant message
    func updateStreamingMessage(_ partial: String) {
        guard let id = messageId, let index = messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        let streamingMessage = messages[index]
        messages[index] = Message(
            id: streamingMessage.id,
            role: streamingMessage.role,
            content: streamingMessage.content + partial
        )
    }

    /// Mark the streaming message complete with final text
    func completeStreamingMessage() {
        guard let id = messageId,
              let idx = messages.firstIndex(where: { $0.id == id })
        else {
            return
        }
        messageId = nil
    }
}
