//  Copyright © 2025 Compiler, Inc. All rights reserved.

/// The Function struct hold's the function call being returned from Compiler with parameters defined by in the applcation
public struct Function<Parameters: Decodable & Sendable>: FunctionCallProtocol {
    private enum CodingKeys: String, CodingKey {
        case id = "function"
        case parameters
        case colloquialDescription = "colloquial_response"
    }
    
    /// Function name
    public let id: String
    
    /// Parameters are Decodable and Sendable and can be anything you need
    public let parameters: Parameters?
    
    /// The description to show the user while this function is being executed.
    public let colloquialDescription: String
    
    public init(id: String, parameters: Parameters?, colloquialDescription: String) {
        self.id = id
        self.parameters = parameters
        self.colloquialDescription = colloquialDescription
    }
}
