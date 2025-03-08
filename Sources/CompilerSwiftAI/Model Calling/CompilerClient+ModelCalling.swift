//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

extension CompilerClient {
    func makeModelCall(
        using metadata: ModelMetadata,
        systemPrompt: String? = nil,
        userPrompt: String,
        state: (any Codable & Sendable)? = nil
    ) async throws -> String {
        let response = try await makeModelCallWithResponse(
            using: metadata,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            state: state
        )
        return response.content
    }

    func makeModelCallWithResponse(
        using metadata: ModelMetadata,
        systemPrompt: String? = nil,
        userPrompt: String,
        state: (any Codable & Sendable)? = nil
    ) async throws -> CompletionResponse {
        let endpoint = "\(baseURL)/v1/apps/\(appID)/end-users/model-call"
        guard let url = URL(string: endpoint) else {
            modelLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }

        modelLogger.debug("Making completion model call to: \(endpoint)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await getValidToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // If state is provided, append it to the userPrompt
        let finalUserPrompt = state.map { "\(userPrompt)\n\nThe current app state is: \($0)" } ?? userPrompt

        let body = CompletionRequest(
            using: metadata,
            systemPrompt: systemPrompt,
            userPrompt: finalUserPrompt
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

        guard 200 ... 299 ~= httpResponse.statusCode else {
            modelLogger.error("Model call failed with status \(httpResponse.statusCode)")
            throw AuthError.serverError("Model call failed with status \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(CompletionResponse.self, from: data)
    }
}
