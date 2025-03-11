//  Copyright 2025 Compiler, Inc. All rights reserved.

import OSLog

struct ChatResponseDTO: Decodable {
    let content: String
}

extension CompilerClient {
    var streamingProviders: [ModelProvider] { [.openai, .anthropic, .google] }

    // Specialized String streaming version
    func makeStreamingModelCall(
        using metadata: ModelMetadata,
        request: CompletionRequestDTO
    ) -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        guard streamingProviders.contains(metadata.provider) else {
            return AsyncThrowingStream {
                $0.finish(
                    throwing: AuthError.serverError(
                        "Only \(streamingProviders.map { $0.rawValue }.joined(separator: ", ")) support streaming"
                    )
                )
            }
        }

        modelLogger.debug("Starting streaming model call")

        // Prepare request URL and headers
        let endpoint = "\(baseURL)/v1/apps/\(appID)/end-users/model-call/stream"
        guard let url = URL(string: endpoint) else {
            modelLogger.error("Invalid URL: \(self.baseURL)")
            return AsyncThrowingStream { $0.finish(throwing: URLError(.badURL)) }
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Set up request with auth token and body
                    let token = try await getValidToken()
                    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    urlRequest.httpBody = try JSONEncoder().encode(request)

                    modelLogger.debug("Starting SSE stream...")

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        modelLogger.error("Invalid response type received")
                        throw AuthError.invalidResponse
                    }

                    guard 200 ... 299 ~= httpResponse.statusCode else {
                        modelLogger.error("Streaming model call failed with status \(httpResponse.statusCode)")
                        throw AuthError.serverError("Streaming model call failed with status \(httpResponse.statusCode)")
                    }

                    for try await line in asyncBytes.lines {
                        modelLogger.debug("Raw SSE line: \(line)")

                        if let chunk = try parseStreamingChunk(from: line) {
                            modelLogger.debug("Chunk received: \(chunk)")
                            continuation.yield(chunk)
                        }
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

    private func parseStreamingChunk(from line: String) throws -> ChatCompletionChunk? {
        // Skip empty lines and comments
        guard !line.isEmpty, !line.hasPrefix(":") else {
            return nil
        }

        // Extract the data part from the SSE format
        guard line.hasPrefix("data: ") else {
            return nil
        }

        let jsonString = String(line.dropFirst(6))
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        return try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
    }
}
