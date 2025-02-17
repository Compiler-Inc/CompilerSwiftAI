//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

public struct FunctionChatView<AppState: Encodable & Sendable, Parameters: Decodable & Sendable>: View {
    @State var model: FunctionChatViewModel<AppState, Parameters>


    public init(state: AppState, client: CompilerClient, describe: @escaping (Function<Parameters>) -> String, execute: @escaping (Function<Parameters>) -> Void) {
        model = FunctionChatViewModel(state: state, client: client, describe: describe, execute: execute)
    }

    public var body: some View {
        VStack(spacing: 4) {
            TextInputView(model: model, process: model.process)
            ProcessingStepsView(steps: model.processingSteps)
        }
    }
}
