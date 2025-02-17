//  Copyright © 2025 Compiler, Inc. All rights reserved.

public protocol TokenManaging: Actor {
    func getValidToken() async throws -> String
}
