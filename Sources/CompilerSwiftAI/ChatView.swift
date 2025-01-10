//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

public struct ChatView<AppState: Encodable & Sendable, Args: Decodable & Sendable>: View {
    
    @State var model = ChatViewModel()
    
    var state: AppState
    var dlm: Service
    var deepgram: DeepgramService?
    var describe: (DLMCommand<Args>) -> String
    var execute: (DLMCommand<Args>) -> ()
    
    public init(state: AppState, dlm: Service, deepgram: DeepgramService? = nil, describe: @escaping (DLMCommand<Args>) -> String, execute: @escaping (DLMCommand<Args>) -> ()) {
        self.state = state
        self.dlm = dlm
        self.deepgram = deepgram
        self.describe = describe
        self.execute = execute
    }
    
    func process(prompt: String) {
        Task {
            model.addStep("Sending request to DLM")
            guard let commands: [DLMCommand<Args>] = try? await dlm.processCommand(prompt, for: state) else { return }
            model.completeLastStep()
            
            for command in commands {
                model.addStep(describe(command))
                execute(command)
                model.completeLastStep()
            }
        }
    }

    public var body: some View {
        VStack(spacing: 4) {
            DLMTextInputView(model: model, process: process)
            ProcessingStepsView(steps: model.processingSteps)
        }
        .frame(minWidth: 200)
        .background(DLMColors.primary10)
        .onAppear {
            model.deepgram = deepgram
            model.setupDeepgramHandlers()
        }
    }
}
