//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

public final actor Service {
    //private let baseURL = "https://backend.compiler.inc/function-call"
    //private let baseURL = "https://backend.compiler.inc/"
    private let baseURL = "http://localhost:3000"
    let appId: UUID

    public init(appId: UUID) {
        self.appId = appId
    }

    public func processFunction<State: Encodable & Sendable, Parameters: Decodable & Sendable>(_ content: String, for state: State, using token: String) async throws -> [Function<Parameters>] {
        print("🚀 Starting processFunction with content: \(content)")

        guard let url = URL(string: baseURL) else {
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
    
    public func makeModelCall(token: String) async {
        
        do {
            let endpoint = "\(baseURL)/v1/apps/\(appId.uuidString)/end-users/model-call"
            guard let url = URL(string: endpoint) else { return }
            
            print("🤖 Making model call to: \(endpoint)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        
        // Include the bundle ID in the request
        let body = AppleAuthRequest(
            id_token: idToken,
            bundle_id: Bundle.main.bundleIdentifier ?? ""
        )
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
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AuthError.serverError("Server returned status code \(httpResponse.statusCode)")
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        print("✅ Successfully got access token")
        
        return authResponse.access_token
    }
}
