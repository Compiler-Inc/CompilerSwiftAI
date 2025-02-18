//  Copyright © 2025 Compiler, Inc. All rights reserved.

/// The Function struct hold's the function call being returned from Compiler with parameters defined by in the applcation
public struct Function<Parameters>: Decodable, Sendable where Parameters: Decodable & Sendable {
    /// Function name
    public let name: String
    /// Parameters are Decodable and Sendable and can be anything you need
    public let parameters: Parameters?

    private enum CodingKeys: String, CodingKey {
        case name = "function"
        case parameters
    }
}
