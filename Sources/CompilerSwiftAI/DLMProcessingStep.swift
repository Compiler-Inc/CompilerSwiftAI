//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

public struct DLMProcessingStep: Identifiable, Hashable {
    
    public let id = UUID()
    let text: String
    var isComplete: Bool
    
    public init(text: String, isComplete: Bool) {
        self.text = text
        self.isComplete = isComplete
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
