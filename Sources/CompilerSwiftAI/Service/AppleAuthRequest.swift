//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct AppleAuthRequest: Codable {
    let idToken: String
    
    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}
