//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct AppleAuthRequest: Codable {
    public let id_token: String
    public let bundle_id: String
    
    public init(id_token: String, bundle_id: String) {
        self.id_token = id_token
        self.bundle_id = bundle_id
    }
}
