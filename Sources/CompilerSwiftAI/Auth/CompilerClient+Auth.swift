//  Copyright © 2025 Compiler, Inc. All rights reserved.\

import Foundation

public struct AuthResponse: Codable {
    public let access_token: String
}

public enum AuthError: Error {
    case invalidIdToken
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError
}

extension CompilerClient {
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
