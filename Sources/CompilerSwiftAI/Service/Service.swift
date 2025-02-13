//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation
import AuthenticationServices
import OSLog

extension Logger {
    private static let subsystem = "CompilerSwiftAI"
    
    /// Logs related to function calling and processing
    static let functionCalls = Logger(subsystem: subsystem, category: "functionCalls")
    
    /// Logs related to model calls, streaming, and responses
    static let modelCalls = Logger(subsystem: subsystem, category: "modelCalls")
    
    /// Logs related to authentication and token management
    static let auth = Logger(subsystem: subsystem, category: "auth")
}

/// A wrapper around Logger that handles debug mode checks
private struct DebugLogger {
    private let logger: Logger
    private let isEnabled: Bool
    
    init(_ logger: Logger, isEnabled: Bool) {
        self.logger = logger
        self.isEnabled = isEnabled
    }
    
    func debug(_ message: @escaping @autoclosure () -> String) {
        guard isEnabled else { return }
        logger.debug("\(message())")
    }
    
    func error(_ message: @escaping @autoclosure () -> String) {
        // Always log errors, regardless of debug mode
        logger.error("\(message())")
    }
}

public protocol TokenManaging: Actor {
    func getValidToken() async throws -> String
}

public final actor Service: TokenManaging {
    // private let baseURL: String = "https://backend.compiler.inc"
    private let baseURL: String = "http://localhost:3000"
    let appId: UUID
    private let keychain: any KeychainManaging
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
            modelLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }
        
        modelLogger.debug("Making model call to: \(endpoint)")
        
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
        
        modelLogger.debug("Request body: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
        
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
        // Verify provider supports streaming
        guard metadata.provider == .openai || metadata.provider == .anthropic else {
            return AsyncThrowingStream { $0.finish(throwing: AuthError.serverError("Only OpenAI and Anthropic support streaming")) }
        }
        
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
