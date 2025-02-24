//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

struct ChatResponseDataTransferObject: Decodable {
    let content: String
}

extension CompilerClient {
    var streamingProviders: [ModelProvider] { [.openai, .anthropic, .gemini] }
    
    // Specialized String streaming version
    func makeStreamingModelCall(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<String, Error> {
        guard streamingProviders.contains(metadata.provider) else {
            return AsyncThrowingStream { $0.finish(throwing: AuthError.serverError("Only \(streamingProviders.map { $0.rawValue}.joined(separator: ", ")) support streaming")) }
        }
        
        modelLogger.debug("Starting streaming model call with \(messages.count) messages")
        
        // Prepare all the non-async parts of the request before the Task
        let endpoint = "\(baseURL)/v1/apps/\(appID.uuidString)/end-users/model-call/stream"
        guard let url = URL(string: endpoint) else {
            modelLogger.error("Invalid URL: \(self.baseURL)")
            return AsyncThrowingStream { $0.finish(throwing: URLError(.badURL)) }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        // If state is provided, append it to the last user message
        let finalMessages: [Message]
        if let state = state,
           let lastUserMessageIndex = messages.lastIndex(where: { $0.role == .user }) {
            var modifiedMessages = messages
            let lastUserMessage = modifiedMessages[lastUserMessageIndex]
            let stateContent = "\(lastUserMessage.content)\n\nThe current app state is: \(state)"
            modifiedMessages[lastUserMessageIndex] = Message(
                id: lastUserMessage.id,
                role: .user,
                content: stateContent
            )
            finalMessages = modifiedMessages
        } else {
            finalMessages = messages
        }
        
        let body = StreamRequest(
            using: metadata,
            messages: finalMessages
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            
            // AppId is only in the endpoint URL, not in query params or body
            request.httpBody = try encoder.encode(body)
            
            modelLogger.debug("Streaming request body JSON: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        } catch {
            modelLogger.error("Failed to encode request: \(error)")
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let token = try await getValidToken()
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    modelLogger.debug("Starting SSE stream...")
                    
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        modelLogger.error("Invalid response type received")
                        throw AuthError.invalidResponse
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        modelLogger.error("Streaming model call failed with status \(httpResponse.statusCode)")
                        throw AuthError.serverError("Streaming model call failed with status \(httpResponse.statusCode)")
                    }
                    
                    for try await line in asyncBytes.lines {
                        modelLogger.debug("Raw SSE line: \(line)")
                        
                        guard let content = try parseChatResponse(from: line) else {
                            continue
                        }
                        
                        modelLogger.debug("Content: \(content.debugDescription)")
                        
                        continuation.yield(content)

                        modelLogger.debug("Content yielded successfully")
                    }
                    
                    modelLogger.debug("SSE stream complete")
                    continuation.finish()
                } catch {
                    modelLogger.error("SSE stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    @available(macOS 14.0, iOS 17.0, *)
    func streamModelResponse(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<Message, Error> {
        modelLogger.debug("Starting streamModelResponse with \(messages.count) messages")
        
        // Capture metadata values before the closure to prevent data races
        let provider = metadata.provider
        let model = metadata.model
        let capabilities = metadata.capabilities
        let temperature = metadata.temperature
        let maxTokens = metadata.maxTokens
        let capturedMetadata = ModelMetadata(
            provider: provider,
            capabilities: capabilities,
            model: model,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = makeStreamingModelCall(
                        using: capturedMetadata,
                        messages: messages,
                        state: state
                    )
                    
                    var streamingMessage = Message(role: .assistant, content: "")
                    continuation.yield(streamingMessage)
                    
                    for try await chunk in stream {
                        streamingMessage = Message(
                            id: streamingMessage.id,
                            role: .assistant,
                            content: streamingMessage.content + chunk
                        )
                        continuation.yield(streamingMessage)
                    }
                    
                    continuation.finish()
                } catch {
                    modelLogger.error("Error in streamModelResponse: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func parseChatResponse(from line: String) throws -> String? {
        // Skip empty lines and comments
        guard !line.isEmpty, !line.hasPrefix(":") else {
            return nil
        }
        
        // Extract the data part from the SSE format
        guard line.hasPrefix("data: ") else {
            return nil
        }
        
        let jsonString = String(line.dropFirst(6))
        
        guard let parsedResponse = try? parseEventMessage(from: jsonString) else {
            print("Couldn't parse repsonse")
            return nil
        }
        
        return parsedResponse.content
    }
    
    private func parseEventMessage(from line: String) throws -> ChatResponseDataTransferObject? {
        guard let data = line.data(using: .utf8) else {
            print("[ChatStreamer] ❌ Failed to convert string to data: \(line)")
            return nil
        }

        do {
            let message = try JSONDecoder().decode(ChatResponseDataTransferObject.self, from: data)
            return message
        } catch {
            print("[ChatStreamer] ❌ JSON decode error: \(error)")
            return nil
        }
    }
}
