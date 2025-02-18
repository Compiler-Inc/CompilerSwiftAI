//  Copyright © 2025 Compiler, Inc. All rights reserved.

import AuthenticationServices

extension CompilerClient {
    public func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async throws -> Bool {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                throw AuthError.invalidToken
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
