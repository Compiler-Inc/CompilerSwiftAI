//  Copyright © 2025 Compiler, Inc. All rights reserved.\

import Foundation

public enum AuthError: Error {
    case invalidIdToken
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError
}

extension CompilerClient {
    /// Gets either the stored Apple ID Token or a refreshed one
    /// - Returns: Token string
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
    
    public func authenticateWithServer(idToken: String) async throws -> String {
        let lowercasedAppID = appID.uuidString.lowercased()
        let endpoint = "\(baseURL)/v1/apps/\(lowercasedAppID)/end-users/apple"
        guard let url = URL(string: endpoint) else {
            authLogger.error("Invalid URL: \(self.baseURL)")
            throw AuthError.invalidResponse
        }
        
        authLogger.debug("Making auth request to: \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["id_token": idToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        authLogger.debug("Request body: \(body)")
        
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
            struct AuthResponse: Codable { let access_token: String }
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
        if let storedToken = await keychain.read(service: "apple-id-token", account: "user") {
            do {
                let accessToken = try await authenticateWithServer(idToken: storedToken)
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
}
