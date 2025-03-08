//
//  NEW_ChatViewModel.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import Combine
import OSLog
import SwiftUI
import Transcriber
import Speech

actor NEW_ChatViewModel: ObservableObject {
    /// `true` when a response is currently streaming
    @Published var streaming: Bool = false
    
    /// Indicates that we are waiting for the first token
    @Published var loading: Bool = false
    
    /// Error message from the server, if any
    @Published var error: String?
    
    /// Info about which model to use
    @Published var modelMetadata: ModelMetadata?
    
    /// Simple logger to show aggregator logs
    private let logger: Logger
    
    private let chatHistory: ChatHistory
    private let client: CompilerClient
    private let defaultModel = ModelMetadata.openAI(.gpt4o)
    
    init(
        client: CompilerClient,
        chatHistory: ChatHistory = .init(),
        logger: Logger = Logger(subsystem: "NEW_ChatViewModel", category: "Aggregator")
    ) {
        self.client = client
        self.logger = logger
        self.chatHistory = chatHistory
    }
    
    func sendMessage(_ text: String) {
        guard !loading && !streaming else { return }
        
        logger.log("sendMessage initiated with text: \"\(text)\". Adding user message.")
        
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.chatHistory.addUserMessage(text)
            
            do {
                try await self?.startStreamingResponse()
            } catch {
                print("error: \(error.localizedDescription)")
                await self?.setError(error: error)
            }

            self?.logger.log("sendMessage completed. isStreaming set to false.")
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
    
    private func setLoading(_ value: Bool) {
        guard value != loading else { return }
        
        loading = value
    }
    
    private func setError(error: Error) {
        self.error = error.localizedDescription
    }
    
    private func startStreamingResponse() async throws {
        let messagesSoFar = await chatHistory.messages.filter { !$0.content.isEmpty }
        
        guard !messagesSoFar.isEmpty else {
            return setStreaming(false)
        }
        
        setLoading(true)
        setStreaming(true)
        
        let stream = await client.streamModelResponse(
            using: modelMetadata ?? defaultModel,
            messages: messagesSoFar
        )
        
        for try await line in stream {
            setLoading(false)
            await chatHistory.updateStreamingMessage(line.content)
        }
        
        setLoading(false)
        setStreaming(false)
    }
}
