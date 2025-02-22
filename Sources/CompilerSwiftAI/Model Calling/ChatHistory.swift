//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

/// A convenience type to help manage conversation history with LLMs
@available(macOS 14.0, iOS 17.0, *)
actor ChatHistory {
    var _messages: [Message]
    var messageID: UUID?
    
    /// We'll store the active continuation if someone requests `messagesStream`.
    var continuation: AsyncStream<[Message]>.Continuation?
    
    var messages: [Message] {
        // Return all messages except those that are *still* streaming
        get async {
            _messages.filter { $0.state == .complete }
        }
    }
    
    /// A continuous stream of *all* messages, including .streaming states
    var messagesStream: AsyncStream<[Message]> {
        AsyncStream { continuation in
            self.continuation = continuation
            // Immediately yield whatever we have
            continuation.yield(_messages)
        }
    }
    
    init(systemPrompt: String) {
        self._messages = [Message(role: .system, content: [.text(systemPrompt)])]
    }
    
    func notifyMessageUpdate() {
        continuation?.yield(_messages)
    }
    
    func addUserMessage(_ content: String) {
        _messages.append(Message(role: .user, content: [.text(content)]))
        notifyMessageUpdate()
    }
    
    func addAssistantMessage(_ content: String) {
        _messages.append(Message(role: .assistant, content: [.text(content)]))
        notifyMessageUpdate()
    }
    
    /// Start a new streaming response from the assistant
    @discardableResult
    func beginStreamingResponse() -> UUID {
        let id = UUID()
        let msg = Message(id: id, role: .assistant, content: [.text("")], state: .streaming(""))
        _messages.append(msg)
        messageID = id
        notifyMessageUpdate()
        return id
    }
    
    /// Update the partial text of the *current* streaming assistant message
    func updateStreamingMessage(_ partial: String) {
        guard let id = messageID,
              let idx = _messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        let old = _messages[idx]
        _messages[idx] = Message(
            id: old.id,
            role: old.role,
            content: [.text(partial)],
            state: .streaming(partial)
        )
        notifyMessageUpdate()
    }
    
    /// Mark the streaming message complete with final text
    func completeStreamingMessage(_ finalContent: String) {
        guard let id = messageID,
              let idx = _messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        _messages[idx] = Message(
            id: id,
            role: .assistant,
            content: [.text(finalContent)],
            state: .complete
        )
        messageID = nil
        notifyMessageUpdate()
    }
    
    func clearHistory(keepingSystemPrompt: Bool = true) {
        messageID = nil
        if keepingSystemPrompt, let systemMessage = _messages.first, systemMessage.role == .system {
            _messages = [systemMessage]
        } else {
            _messages.removeAll()
        }
        notifyMessageUpdate()
    }
    
    deinit {
        continuation?.finish()
    }
}
