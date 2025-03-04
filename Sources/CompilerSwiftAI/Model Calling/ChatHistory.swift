//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

/// A convenience type to help manage conversation history with LLMs
@available(macOS 14.0, iOS 17.0, *)
actor ChatHistory {
    var _messages: [Message]
    var messageID: String?

    /// We'll store the active continuation if someone requests `messagesStream`.
    var continuation: AsyncStream<[Message]>.Continuation?

    var messages: [Message] {
        // Return all messages except those that are *still* streaming
        get async {
            _messages
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
        _messages = [Message.systemMessage(content: systemPrompt)]
    }

    func notifyMessageUpdate() {
        continuation?.yield(_messages)
    }

    func addUserMessage(_ content: String) {
        _messages.append(Message.userMessage(content: content))
        notifyMessageUpdate()
    }

    func addAssistantMessage(_ content: String) {
        _messages.append(Message.assistantMessage(content: content))
        notifyMessageUpdate()
    }

    /// Start a new streaming response from the assistant
    @discardableResult
    func beginStreamingResponse() -> String {
        let msg = Message.assistantMessage(content: "")
        _messages.append(msg)
        messageID = msg.id
        notifyMessageUpdate()
        return msg.id
    }

    /// Update the partial text of the *current* streaming assistant message
    func updateStreamingMessage(_ partial: String) {
        guard let id = messageID,
              let idx = _messages.firstIndex(where: { $0.id == id })
        else {
            return
        }
        let old = _messages[idx]
        _messages[idx] = Message(
            id: old.id,
            role: old.role,
            content: old.content + partial
        )
        notifyMessageUpdate()
    }

    /// Mark the streaming message complete with final text
    func completeStreamingMessage(_ finalContent: String) {
        guard let id = messageID,
              let idx = _messages.firstIndex(where: { $0.id == id })
        else {
            return
        }
        _messages[idx] = Message(
            id: id,
            role: .assistant,
            content: finalContent
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
