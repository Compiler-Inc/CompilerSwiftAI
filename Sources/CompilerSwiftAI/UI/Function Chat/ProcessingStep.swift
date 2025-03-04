//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

struct ProcessingStep: Identifiable, Hashable {
    let id = UUID()
    let text: String
    var isComplete: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
