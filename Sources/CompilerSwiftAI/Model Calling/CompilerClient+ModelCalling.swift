//  Copyright © 2025 Compiler, Inc. All rights reserved.

import OSLog

extension CompilerClient {
    // Backend streaming chunk format
    private struct StreamChunk: Codable {
        let data: String
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
    

    

}
