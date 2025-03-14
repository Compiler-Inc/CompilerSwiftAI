//  Copyright 2025 Compiler, Inc. All rights reserved.

import OSLog

extension CompilerClient {
    func makeModelCallWithResponse(
        request: CompletionRequestDTO
    ) async throws -> ChatCompletionResponse {
        let endpoint = "\(baseURL)/v1/apps/\(appID)/end-users/model-call"
        guard let url = URL(string: endpoint) else {
            modelLogger.error("Invalid URL: \(self.baseURL)")
            throw URLError(.badURL)
        }

        modelLogger.debug("Making completion model call to: \(endpoint)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = try await getValidToken()
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(request)
        urlRequest.httpBody = jsonData

        return try await performRequest(urlRequest)
    }

    func performRequest(_ request: URLRequest) async throws -> ChatCompletionResponse {
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

        return try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
    }
}
