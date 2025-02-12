//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation
import AuthenticationServices

public protocol TokenManaging: Actor {
    func getValidToken() async throws -> String
}

public final actor Service: TokenManaging {
    // private let baseURL: String = "https://backend.compiler.inc"
    private let baseURL: String = "http://localhost:3000"
    let appId: UUID
    private let keychain: any KeychainManaging

    public init(appId: UUID, keychain: any KeychainManaging = KeychainHelper.standard) {
        self.appId = appId
        self.keychain = keychain
    }

    public func processFunction<State: Encodable & Sendable, Parameters: Decodable & Sendable>(_ content: String, for state: State, using token: String) async throws -> [Function<Parameters>] {
        print("🚀 Starting processFunction with content: \(content)")

        let endpoint = "\(baseURL)/v1/function-call/\(appId.uuidString)"
        
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid URL: \(baseURL)")
            throw URLError(.badURL)
        }
        print("✅ URL created: \(url)")

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

        print("📤 Request Headers:", urlRequest.allHTTPHeaderFields ?? [:])
        print("📦 Request Body:", String(data: jsonData, encoding: .utf8) ?? "nil")

        print("⏳ Starting network request...")

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        print("📥 Response received")
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Status code: \(httpResponse.statusCode)")
            print("🔍 Response headers: \(httpResponse.allHeaderFields)")
        }
        print("📄 Response body: \(String(data: data, encoding: .utf8) ?? "nil")")

        print("Attempting to decode: \(String(data: data, encoding: .utf8) ?? "nil")")
        do {
            let functions = try JSONDecoder().decode([Function<Parameters>].self, from: data)
            print("✅ Decoded response: \(functions)")
            return functions
        } catch {
            print("❌ Decoding error: \(error)")
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

    // Default String response version
    public func makeModelCall(
        systemPrompt: String,
        userPrompt: String,
        using metadata: ModelMetadata,
        state: (any Codable & Sendable)? = nil
    ) async throws -> String {
        let response: ModelCallResponse<String> = try await makeModelCallWithResponse(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            using: metadata,
            state: state
        )
        return response.content
    }
    
    // Generic version for custom response types
    public func makeModelCallWithResponse<Response: Codable & Sendable>(
        systemPrompt: String,
        userPrompt: String,
        using metadata: ModelMetadata,
        state: (any Codable & Sendable)? = nil
    ) async throws -> ModelCallResponse<Response> {
        let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call"
        guard let url = URL(string: endpoint) else { 
            throw URLError(.badURL)
        }
        
        print("🤖 Making model call to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = try await getValidToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Append state info to userPrompt if available
        let finalUserPrompt: String
        if let state = state {
            finalUserPrompt = "\(userPrompt)\n\nThe current app state is: \(state)"
        } else {
            finalUserPrompt = userPrompt
        }
        
        let body = ModelCallRequest(
            systemPrompt: systemPrompt,
            userPrompt: finalUserPrompt,
            provider: metadata.provider,
            model: metadata.id
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(body)
        request.httpBody = jsonData
        
        print("📤 Request body:")
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        print("📥 Response headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Raw response data: \(responseString)")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AuthError.serverError("Model call failed with status \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ModelCallResponse<Response>.self, from: data)
    }
    
    // Backend streaming chunk format
    private struct StreamChunk: Codable {
        let data: String
    }
    
    // Specialized String streaming version
    public func makeStreamingModelCall(
        systemPrompt: String,
        userPrompt: String,
        using metadata: ModelMetadata,
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = makeStreamingModelCallWithResponse(
                        systemPrompt: systemPrompt,
                        userPrompt: userPrompt,
                        using: metadata,
                        state: state
                    )
                    
                    var buffer = ""
                    var lastCharWasSpace = true // Track if we just emitted a space
                    
                    for try await chunk in stream {
                        let text = chunk.data.precomposedStringWithCanonicalMapping
                        
                        // If this chunk starts with a letter and the last char wasn't a space,
                        // we probably need a space
                        if !lastCharWasSpace && !text.isEmpty && text.first?.isLetter == true {
                            buffer += " "
                        }
                        
                        buffer += text
                        
                        // If we hit certain boundaries, emit the buffer
                        if text.contains(where: { $0.isWhitespace || $0.isPunctuation }) {
                            continuation.yield(buffer)
                            buffer = ""
                            lastCharWasSpace = text.last?.isWhitespace == true
                        } else if buffer.count > 30 {
                            // If buffer is getting long, emit it
                            continuation.yield(buffer)
                            buffer = ""
                            lastCharWasSpace = false
                        }
                    }
                    
                    // Emit any remaining text
                    if !buffer.isEmpty {
                        continuation.yield(buffer)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func makeStreamingModelCallWithResponse(
        systemPrompt: String,
        userPrompt: String,
        using metadata: ModelMetadata,
        state: (any Codable & Sendable)? = nil
    ) -> AsyncThrowingStream<StreamChunk, Error> {
        // Verify provider supports streaming
        guard metadata.provider == .openai || metadata.provider == .anthropic else {
            return AsyncThrowingStream { $0.finish(throwing: AuthError.serverError("Only OpenAI and Anthropic support streaming")) }
        }
        
        // Prepare all the non-async parts of the request before the Task
        let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call/stream"
        guard let url = URL(string: endpoint) else {
            return AsyncThrowingStream { $0.finish(throwing: URLError(.badURL)) }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        
        let finalUserPrompt: String
        if let state = state {
            finalUserPrompt = "\(userPrompt)\n\nThe current app state is: \(state)"
        } else {
            finalUserPrompt = userPrompt
        }
        
        let body = ModelCallRequest(
            systemPrompt: systemPrompt,
            userPrompt: finalUserPrompt,
            provider: metadata.provider,
            model: metadata.id
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(body)
        } catch {
            return AsyncThrowingStream { $0.finish(throwing: error) }
        }
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let token = try await getValidToken()
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw AuthError.invalidResponse
                    }
                    
                    guard 200...299 ~= httpResponse.statusCode else {
                        throw AuthError.serverError("Streaming model call failed with status \(httpResponse.statusCode)")
                    }
                    
                    for try await line in asyncBytes.lines {
                        // Skip empty lines
                        guard !line.isEmpty else { continue }
                        
                        print("📝 Raw line: \(line)")
                        
                        if line.hasPrefix("data:") {
                            // Extract everything after "data:" and trim whitespace
                            let content = String(line.dropFirst("data:".count)).trimmingCharacters(in: .whitespaces)
                            print("📄 Content: \(content)")
                            
                            // Skip empty content
                            guard !content.isEmpty else { continue }
                            
                            continuation.yield(StreamChunk(data: content))
                        }
                        // Ignore other event types (id, etc)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func authenticateWithServer(idToken: String) async throws -> String {
        let lowercasedAppId = appId.uuidString.lowercased()
        let endpoint = "\(baseURL)/v1/apps/\(lowercasedAppId)/end-users/apple"
        guard let url = URL(string: endpoint) else {
            throw AuthError.invalidResponse
        }
        
        print("🔐 Making auth request to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = AppleAuthRequest(idToken: idToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 Request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            print("✅ Successfully got access token")
            return authResponse.access_token
        case 400:
            throw AuthError.serverError("Bundle ID mismatch or SIWA not enabled")
        case 401:
            throw AuthError.serverError("Invalid or expired Apple token")
        case 500:
            throw AuthError.serverError("Server encryption/decryption issues")
        default:
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

    public func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async throws -> Bool {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                throw AuthError.invalidIdToken
            }
            
            // Store Apple ID token - this acts as our "refresh token"
            // Apple ID tokens can be reused for a while (usually days to weeks)
            await keychain.save(idToken, service: "apple-id-token", account: "user")
            
            let accessToken = try await authenticateWithServer(idToken: idToken)
            await keychain.save(accessToken, service: "access-token", account: "user")
            
            return true
            
        case .failure(let error):
            throw AuthError.networkError(error)
        }
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
}
