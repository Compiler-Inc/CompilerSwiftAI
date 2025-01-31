//  Copyright © 2025 Compiler, Inc. All rights reserved.

public typealias ModelID = String

public struct ModelMetadata: Codable {
    let id: ModelID
    let provider: ModelProvider
    let capabilities: [ModelCapability]
} 
