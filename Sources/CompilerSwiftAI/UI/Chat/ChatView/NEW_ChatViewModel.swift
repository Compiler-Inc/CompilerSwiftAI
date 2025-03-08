//
//  NEW_ChatViewModel.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI
import Combine
import OSLog

actor NEW_ChatViewModel: ObservableObject {
    /// `true` when a response is currently streaming
    @Published var streaming: Bool = false
    
    /// Indicates that we are waiting for the first token
    @Published var loading: Bool = false
    
    /// Error message from the server, if any
    @Published var error: String?
    
    /// Simple logger to show aggregator logs
    private let logger: Logger
    
    private let chatHistory: ChatHistory
    
    init(
        chatHistory: ChatHistory = .init(),
        logger: Logger = Logger(subsystem: "NEW_ChatViewModel", category: "Aggregator")
    ) {
        self.logger = logger
        self.chatHistory = chatHistory
    }
    
    func sendMessage(_ text: String) {
        guard !loading && !streaming else { return }
        
        logger.log("sendMessage initiated with text: \"\(text)\". Adding user message.")
        loading = true
        
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.chatHistory.addUserMessage(text)

            // Mark UI as streaming
            await self?.setStreaming(true)
//
//            var accumulated = ""
//            do {
//                // Grab all messages so far (user + history)
//                let messagesSoFar = await self.chatHistory.messages.filter({ !$0.content.isEmpty })
//                self.logger.log("Calling service.streamModelResponse with \(messagesSoFar.count) messages.")
//
//                // Get immutable streaming configuration
//                let config = await self.client.makeStreamingSession()
//                let stream = await self.client.streamModelResponse(using: config.metadata, messages: messagesSoFar)
//
//                var chunkCount = 0
//                for try await partialMessage in stream {
//                    chunkCount += 1
//                    accumulated = partialMessage.content
//
//                    // Log each chunk size
//                    self.logger.log("Chunk #\(chunkCount): partial content size=\(accumulated.count). Updating streaming message.")
//
//                    // Update partial text in chatHistory
//                    await self.chatHistory.updateStreamingMessage(accumulated)
//                }
//
//                // SSE finished
//                self.logger.log("Streaming complete. Final content size=\(accumulated.count). Completing streaming message.")
//                await self.chatHistory.completeStreamingMessage(accumulated)
//            } catch {
//                self.logger.error("❌ SSE stream error: \(error). Completing with partial content.")
//                await self.chatHistory.completeStreamingMessage(accumulated)
//            }
//
//            // Done streaming
//            await MainActor.run { self.isStreaming = false }
//            self.logger.log("sendMessage completed. isStreaming set to false.")
        }
    }
    
    private func setStreaming(_ value: Bool) {
        streaming = value
        
        Task {
            if value {
                await chatHistory.beginStreamingResponse()
            } else {
                await chatHistory.completeStreamingMessage()
            }
        }
    }
}
