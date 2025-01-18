//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

public struct ChatView<AppState: Encodable & Sendable, Args: Decodable & Sendable>: View {
    
    @State var model = ChatViewModel()
    @State private var speechService = SpeechRecognitionService()
    
    var state: AppState
    var dlm: Service
    var describe: (Command<Args>) -> String
    var execute: (Command<Args>) -> ()
    
    public init(state: AppState, dlm: Service, describe: @escaping (Command<Args>) -> String, execute: @escaping (Command<Args>) -> ()) {
        self.state = state
        self.dlm = dlm
        self.describe = describe
        self.execute = execute
    }
    
    func process(prompt: String) {
        Task {
            model.addStep("Sending request to Compiler")
            guard let commands: [Command<Args>] = try? await dlm.processCommand(prompt, for: state) else { return }
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
            TextInputView(model: model, process: process)
            ProcessingStepsView(steps: model.processingSteps)
        }
        .frame(minWidth: 200)
        .background(DLMColors.primary10)
        .onAppear {
            model.speechService = speechService
            model.setupSpeechHandlers()
        }
    }
}
