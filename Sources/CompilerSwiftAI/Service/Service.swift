//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation
import AuthenticationServices

public protocol TokenManaging: Actor {
    func getValidToken() async throws -> String
}

public final actor Service: TokenManaging {
    private let baseURL = "https://backend.compiler.inc/"
    
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

    public func makeModelCall() async {
        do {
            let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call"
            guard let url = URL(string: endpoint) else { return }
            
            print("🤖 Making model call to: \(endpoint)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Get a fresh token
            let token = try await getValidToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body = ModelCallRequest(
                systemPrompt: "You are a helpful assistant",
                userPrompt: "Hello!",
                provider: .openai,
                model: OpenAIModels.gpt4oMini.rawValue
            )
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(body)
            
            print("📤 Request body:")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            
            request.httpBody = jsonData
            
            print("🔑 Using token: \(token)")
            
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
            
            do {
                let modelResponse = try JSONDecoder().decode(ModelCallResponse.self, from: data)
                print("✅ Successfully decoded response: \(modelResponse)")
                // Just use the content as our response
//                await MainActor.run { self.modelResponse = modelResponse.content }
            } catch {
                // If decoding fails, just show the raw response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Using raw response: \(responseString)")
//                    await MainActor.run { self.modelResponse = responseString }
                }
            }
        } catch {
            print("❌ Error: \(error)")
//            await MainActor.run { self.errorMessage = error.localizedDescription }
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
