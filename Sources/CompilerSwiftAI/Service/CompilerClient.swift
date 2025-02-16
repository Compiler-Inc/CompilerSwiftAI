//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

public final actor CompilerClient: TokenManaging {
    private let baseURL: String = "https://backend.compiler.inc"
//    private let baseURL: String = "http://localhost:3000"
    let appId: UUID
    internal let keychain: any KeychainManaging
    private let functionLogger: DebugLogger
    private let modelLogger: DebugLogger
    private let authLogger: DebugLogger

    public init(appId: UUID, keychain: any KeychainManaging = KeychainHelper.standard, enableDebugLogging: Bool = false) {
        self.appId = appId
        self.keychain = keychain
        self.functionLogger = DebugLogger(Logger.functionCalls, isEnabled: enableDebugLogging)
        self.modelLogger = DebugLogger(Logger.modelCalls, isEnabled: enableDebugLogging)
        self.authLogger = DebugLogger(Logger.auth, isEnabled: enableDebugLogging)
    }

    public func processFunction<State: Encodable & Sendable, Parameters: Decodable & Sendable>(_ content: String, for state: State, using token: String) async throws -> [Function<Parameters>] {
        functionLogger.debug("Starting processFunction with content: \(content)")

        let endpoint = "\(baseURL)/v1/function-call/\(appId.uuidString)"
        
        guard let url = URL(string: endpoint) else {
            functionLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }
        
        functionLogger.debug("URL created: \(url)")

        let request = Request(
            id: appId.uuidString,
            prompt: content,
            state: state
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get a fresh token
        let token = try await getValidToken()
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(request)
        urlRequest.httpBody = jsonData

        functionLogger.debug("Request Headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        functionLogger.debug("Request Body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        functionLogger.debug("Starting network request...")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        if let httpResponse = response as? HTTPURLResponse {
            functionLogger.debug("Status code: \(httpResponse.statusCode)")
            functionLogger.debug("Response headers: \(httpResponse.allHeaderFields)")
        }
        functionLogger.debug("Response body: \(String(data: data, encoding: .utf8) ?? "nil")")

        do {
            let functions = try JSONDecoder().decode([Function<Parameters>].self, from: data)
            functionLogger.debug("Decoded response: \(functions)")
            return functions
        } catch {
            functionLogger.error("Decoding error: \(error)")
            throw error
        }
    }
    
    public func getValidToken() async throws -> String {
        // First try to get the stored apple id token
           if let appleIdToken = await keychain.read(service: "apple-id-token", account: "user") {
            do {
                // Try to refresh the token
                let newToken = try await authenticateWithServer(idToken: appleIdToken)
                await keychain.save(newToken, service: "access-token", account: "user")
                return newToken
            } catch {
                throw error
            }
        }
        throw AuthError.invalidIdToken
    }

    public func makeModelCall(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) async throws -> String {
        let response = try await makeModelCallWithResponse(
            using: metadata,
            messages: messages,
            state: state
        )
        return response.content
    }
    
    public func makeModelCallWithResponse(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) async throws -> ModelCallResponse {
        let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call"
        guard let url = URL(string: endpoint) else { 
            modelLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }
        
        modelLogger.debug("Making model call to: \(endpoint)")
        modelLogger.debug("Using \(messages.count) messages")
        modelLogger.debug("Message roles: \(messages.map { $0.role.rawValue })")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = try await getValidToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // If state is provided, append it to the last user message
        let finalMessages: [Message]
        if let state = state,
           let lastUserMessageIndex = messages.lastIndex(where: { $0.role == .user }) {
            var modifiedMessages = messages
            let lastUserMessage = modifiedMessages[lastUserMessageIndex]
            modifiedMessages[lastUserMessageIndex] = Message(
                id: lastUserMessage.id,
                role: .user,
                content: "\(lastUserMessage.content)\n\nThe current app state is: \(state)"
            )
            finalMessages = modifiedMessages
        } else {
            finalMessages = messages
        }
        
        let body = ModelCallRequest(
            using: metadata,
            messages: finalMessages
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(body)
        request.httpBody = jsonData
        
        modelLogger.debug("Full request body JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            modelLogger.error("Invalid response type received")
            throw AuthError.invalidResponse
        }
        
        modelLogger.debug("Response status: \(httpResponse.statusCode)")
        modelLogger.debug("Response headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            modelLogger.debug("Raw response data: \(responseString)")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            modelLogger.error("Model call failed with status \(httpResponse.statusCode)")
            throw AuthError.serverError("Model call failed with status \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ModelCallResponse.self, from: data)
    }
    
    // Backend streaming chunk format
    private struct StreamChunk: Codable {
        let data: String
    }
    
    // Specialized String streaming version
    public func makeStreamingModelCall(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<String, Error> {
        // Verify provider supports streaming
        guard metadata.provider == .openai || metadata.provider == .anthropic else {
            return AsyncThrowingStream { $0.finish(throwing: AuthError.serverError("Only OpenAI and Anthropic support streaming")) }
        }
        
        modelLogger.debug("Starting streaming model call with \(messages.count) messages")
        
        // Prepare all the non-async parts of the request before the Task
        let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call/stream"
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
            modifiedMessages[lastUserMessageIndex] = Message(
                id: lastUserMessage.id,
                role: .user,
                content: "\(lastUserMessage.content)\n\nThe current app state is: \(state)"
            )
            finalMessages = modifiedMessages
        } else {
            finalMessages = messages
        }
        
        let body = ModelCallRequest(
            using: metadata,
            messages: finalMessages
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(body)
            request.httpBody = jsonData
            
            modelLogger.debug("Streaming request body JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
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
                        modelLogger.debug("Raw SSE line [\(line.count) bytes]: \(line)")
                        
                        // Skip non-SSE lines (like id: lines)
                        guard line.hasPrefix("data:") else { 
                            modelLogger.debug("Skipping non-SSE line")
                            continue 
                        }
                        
                        // Get everything after "data:"
                        let content = String(line.dropFirst("data:".count))
                        
                        // If it's just a space or empty after "data:", yield a newline
                        if content.trimmingCharacters(in: .whitespaces).isEmpty {
                            modelLogger.debug("Empty data line - yielding newline")
                            continuation.yield("\n")
                            continue
                        }
                        
                        // For non-empty content, trim just the leading space after "data:"
                        let trimmedContent = content.hasPrefix(" ") ? String(content.dropFirst()) : content
                        modelLogger.debug("Content: \(trimmedContent.debugDescription)")
                        
                        // Yield the content
                        continuation.yield(trimmedContent)
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
    
    public func authenticateWithServer(idToken: String) async throws -> String {
        let lowercasedAppId = appId.uuidString.lowercased()
        let endpoint = "\(baseURL)/v1/apps/\(lowercasedAppId)/end-users/apple"
        guard let url = URL(string: endpoint) else {
            authLogger.error("Invalid URL: \(self.baseURL)")
            throw AuthError.invalidResponse
        }
        
        authLogger.debug("Making auth request to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AppleAuthRequest(idToken: idToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        authLogger.debug("Request body: \(String(describing: body))")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            authLogger.error("Invalid response type received")
            throw AuthError.invalidResponse
        }
        
        authLogger.debug("Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            authLogger.debug("Response body: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            authLogger.debug("Successfully got access token")
            return authResponse.access_token
        case 400:
            authLogger.error("Bundle ID mismatch or SIWA not enabled")
            throw AuthError.serverError("Bundle ID mismatch or SIWA not enabled")
        case 401:
            authLogger.error("Invalid or expired Apple token")
            throw AuthError.serverError("Invalid or expired Apple token")
        case 500:
            authLogger.error("Server encryption/decryption issues")
            throw AuthError.serverError("Server encryption/decryption issues")
        default:
            authLogger.error("Server returned status code \(httpResponse.statusCode)")
            throw AuthError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
    }
    
    public func attemptAutoLogin() async throws -> Bool {
        if let storedAppleIdToken = await keychain.read(service: "apple-id-token", account: "user") {
            do {
                let accessToken = try await authenticateWithServer(idToken: storedAppleIdToken)
                await keychain.save(accessToken, service: "access-token", account: "user")
                return true
            } catch AuthError.serverError("Invalid or expired Apple token") {
                // Apple ID token expired, need fresh sign in
                return false
            } catch {
                throw error
            }
        }
        return false
    }
    
    private func handleError(_ error: Error) -> String {
        switch error {
        case AuthError.invalidIdToken:
            return "Failed to get Apple ID token"
        case AuthError.networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        case AuthError.invalidResponse:
            return "Invalid server response"
        case AuthError.serverError(let message):
            return "Server error: \(message)"
        case AuthError.decodingError:
            return "Failed to process server response"
        default:
            return "An unexpected error occurred"
        }
    }

    @available(macOS 14.0, iOS 17.0, *)
    public func streamModelResponse(
        using metadata: ModelMetadata,
        messages: [Message],
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<Message, Error> {
        modelLogger.debug("Starting streamModelResponse with \(messages.count) messages")
        
        // Capture metadata values before the closure to prevent data races
        let provider = metadata.provider
        let modelId = metadata.id
        let capabilities = metadata.capabilities
        let capturedMetadata = ModelMetadata(provider: provider, capabilities: capabilities, id: modelId)
        
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
}
