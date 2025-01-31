//  Copyright © 2025 Compiler, Inc. All rights reserved.

public enum AuthError: Error {
    case invalidIdToken
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError
}
