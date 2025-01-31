//  Copyright © 2025 Compiler, Inc. All rights reserved.

public struct Function<Parameters>: Decodable, Sendable where Parameters: Decodable & Sendable {
    public let name: String
    public let parameters: Parameters?

    private enum CodingKeys: String, CodingKey {
        case name = "function"
        case parameters
    }
}
