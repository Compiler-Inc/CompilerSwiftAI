//
//  File.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/8/25.
//

import Foundation

public protocol FunctionCallProtocol: Decodable & Sendable {
    associatedtype Parameters: Decodable & Sendable
    
    /// The identifier for this function
    var id: String { get }
    
    /// All the parameters for this function type.
    var parameters: Parameters { get }
    
    /// The description to show the user while this function is being executed.
    var colloquialDescription: String { get }
}
