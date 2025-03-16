//  Copyright © 2025 Compiler, Inc. All rights reserved.

import AuthenticationServices

public extension CompilerClient {
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>, nonce: String?) async throws {
        switch result {
        case let .success(auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8)
            else {
                throw AuthError.invalidToken
            }

            // Store Apple ID token
            await keychain.save(idToken, service: "apple-id-token", account: "user")

            // Store the nonce for verification
            if let nonce = nonce {
                await keychain.save(nonce, service: "apple-nonce", account: "user")
            }
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            let formatter = PersonNameComponentsFormatter()

            let accessToken = try await authenticateWithServer(
                idToken: idToken,
                nonce: nonce,
                email: email,
                name: fullName.map { formatter.string(from: $0) }
            )
            
            await keychain.save(accessToken, service: "access-token", account: "user")
        case let .failure(error):
            throw AuthError.networkError(error)
        }
    }
}
