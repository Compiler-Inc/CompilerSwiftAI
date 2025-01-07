//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

public struct DLMView<AppState: Encodable & Sendable, Args: Decodable & Sendable>: View {
    
    @State var model = DLMViewModel()
    
    var state: AppState
    var dlm: DLMService
    var deepgram: DeepgramService?
    var execute: ([DLMCommand<Args>]) -> ()
    
    public init(state: AppState, dlm: DLMService, deepgram: DeepgramService? = nil, execute: @escaping ([DLMCommand<Args>]) -> ()) {
        self.state = state
        self.dlm = dlm
        self.execute = execute
        self.deepgram = deepgram
    }
    
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

    public var body: some View {
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
