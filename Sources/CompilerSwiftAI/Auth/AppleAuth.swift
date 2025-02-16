//  Copyright © 2025 Compiler, Inc. All rights reserved.

import AuthenticationServices

public struct AppleAuthRequest: Codable {
    let idToken: String
    
    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}

extension Service {
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
}
