//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

// Response model
public struct Function<Parameters>: Decodable, Sendable where Parameters: Decodable & Sendable {
    public let name: String
    public let parameters: Parameters?
    
    private enum CodingKeys: String, CodingKey {
        case name = "function"
        case parameters
    }
}

// Request model
struct Request<State>: Encodable, Sendable where State: Encodable & Sendable {
    let id: String
    let prompt: String
    let state: State
}

public final actor Service {
    private let baseURL = "https://backend.compiler.inc/function-call"

    let apiKey: String
    let appId: String

    public init(apiKey: String, appId: String) {
        self.apiKey = apiKey
        self.appId = appId
    }

    public func processFunction<State: Encodable & Sendable, Parameters: Decodable & Sendable>(_ content: String, for state: State) async throws -> [Function<Parameters>] {
        print("🚀 Starting processFunction with content: \(content)")

        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw URLError(.badURL)
        }
        print("✅ URL created: \(url)")

        let request = Request(
            id: appId,
            prompt: content,
            state: state
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")

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

}
