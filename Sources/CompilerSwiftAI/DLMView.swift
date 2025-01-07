//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct DLMView<AppState: Encodable & Sendable, Args: Decodable & Sendable>: View {
    
    var state: AppState
    @State var model = DLMViewModel()
    var dlm: DLMService
    var execute: ([DLMCommand<Args>]) -> ()
    var deepgram: DeepgramService?
    
    func process(prompt: String) {
        Task {
            model.addStep("Sending request to DLM")
            guard let commands: [DLMCommand<Args>] = try? await dlm.processCommand(prompt, for: state) else { return }
            model.completeLastStep()
            model.addStep("Executing commands")
            execute(commands)
            model.completeLastStep()
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            DLMTextInputView(model: model, process: process)
            DLMProcessingStepsView(model: model)
        }
        .frame(minWidth: 200)
        .background(DLMColors.primary10)
        .onAppear {
            model.deepgram = deepgram
            model.setupDeepgramHandlers()
        }
    }
}
