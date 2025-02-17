//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

public struct FunctionChatView<AppState: Encodable & Sendable, Parameters: Decodable & Sendable>: View {
    @State var model = FunctionChatViewModel()
//    @State private var speechService = SpeechRecognitionService()

    var state: AppState
    var client: CompilerClient
    var describe: (Function<Parameters>) -> String
    var execute: (Function<Parameters>) -> Void

    public init(state: AppState, service: CompilerClient, describe: @escaping (Function<Parameters>) -> String, execute: @escaping (Function<Parameters>) -> Void) {
        self.state = state
        self.client = service
        self.describe = describe
        self.execute = execute
    }

    func process(prompt: String) {
        Task {
            model.addStep("Sending request to Compiler")
            guard let functions: [Function<Parameters>] = try? await client.processFunction(prompt, for: state, using: "") else { return }
            model.completeLastStep()

            for function in functions {
                model.addStep(describe(function))
                execute(function)
                model.completeLastStep()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 4) {
            TextInputView(model: model, process: process)
            ProcessingStepsView(steps: model.processingSteps)
        }
        .frame(minWidth: 200)
        .onAppear {
//            model.speechService = speechService
            model.setupSpeechHandlers()
        }
    }
}
