//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

// Request model
public struct Request<State>: Encodable, Sendable where State: Encodable & Sendable {
    let id: String
    let prompt: String
    let state: State
}
