//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

extension CompilerClient {    
    /// Create an array of functions with parameters based on a user prompt and state of the app
    /// - Parameters:
    ///   - prompt: Words to extract semantic intention from
    ///   - state: Current state of your app (as defined by the developer, only needs to conform to Encodable and Sendable)
    ///   - token: Authorization token
    /// - Returns: An array of functions with Parameters that are both Decodable and Sendable
    public func processFunction<State: Encodable & Sendable, Parameters: Decodable & Sendable>(_ prompt: String, for state: State, using token: String) async throws -> [Function<Parameters>] {
        functionLogger.debug("Starting processFunction with prompt: \(prompt)")

        let endpoint = "\(baseURL)/v1/function-call/\(appId.uuidString)"
        
        guard let url = URL(string: endpoint) else {
            functionLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }
        
        functionLogger.debug("URL created: \(url)")

        let request = Request(id: appId.uuidString, prompt: prompt, state: state)

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



}
