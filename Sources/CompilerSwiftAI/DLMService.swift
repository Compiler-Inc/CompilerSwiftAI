//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

// Response model
public struct DLMCommand<Args>: Decodable, Sendable where Args: Decodable & Sendable {
    public let command: String
    public let args: Args?
}

// Request model
struct DLMRequest<State>: Encodable, Sendable where State: Encodable & Sendable {
    let id: String
    let prompt: String
    let current_state: State
}

public final actor DLMService {
    private let baseURL = "https://backend.compiler.inc/function-call"
    var manualCommand: String?

    let apiKey: String
    let appId: String

    public init(apiKey: String, appId: String) {
        self.apiKey = apiKey
        self.appId = appId
    }

    public func processCommand<State: Encodable & Sendable, Args: Decodable & Sendable>(_ content: String, for state: State) async throws -> [DLMCommand<Args>] {
        print("🚀 Starting processCommand with content: \(content)")

        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            throw URLError(.badURL)
        }
        print("✅ URL created: \(url)")

        let request = DLMRequest(
            id: appId,
            prompt: content,
            current_state: state
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
            let commands = try JSONDecoder().decode([DLMCommand<Args>].self, from: data)
            print("✅ Decoded response: \(commands)")
            return commands
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }

}
