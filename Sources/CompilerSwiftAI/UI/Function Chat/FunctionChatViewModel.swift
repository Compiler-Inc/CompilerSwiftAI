//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI
import Speech

@MainActor
@Observable
class FunctionChatViewModel<AppState: Encodable & Sendable, Parameters: Decodable & Sendable> {
    var inputText = ""
    var isRecording = false
    var processingSteps: [ProcessingStep] = []

    // Voice input handling
    private let speechService: SpeechRecognitionService
    var authStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    var errorMessage: String = ""
    
    var state: AppState
    var client: CompilerClient
    var describe: (Function<Parameters>) -> String
    var execute: (Function<Parameters>) -> Void

    
    init(state: AppState, client: CompilerClient, describe: @escaping (Function<Parameters>) -> String, execute: @escaping (Function<Parameters>) -> Void) {
        self.speechService = SpeechRecognitionService()
        self.state = state
        self.client = client
        self.describe = describe
        self.execute = execute
    }
    
    func requestSpeechAuthorization() async {
        authStatus = await speechService.requestAuthorization()
    }

    func toggleRecording() {
        if isRecording {
            Task {
                await speechService.stopRecording()
                isRecording = false
            }
        } else {
            Task {
                let authStatus = await speechService.requestAuthorization()
                guard authStatus == .authorized else {
                    errorMessage = "Speech recognition not authorized"
                    return
                }
                
                do {
                    let stream = try await speechService.startRecordingStream()
                    isRecording = true
                    
                    for try await partialResult in stream {
                        self.inputText = partialResult
                    }
                    
                    // Stream completed (silence detected), send the complete transcription
                    if !self.inputText.isEmpty {
                        process(prompt: self.inputText)
//                        sendMessage(self.inputText)
//                        self.inputText = ""
                    }
                    
                    isRecording = false
                } catch {
                    errorMessage = error.localizedDescription
                    isRecording = false
                }
            }
        }
    }

    func addStep(_ description: String) {
        processingSteps.append(ProcessingStep(text: description, isComplete: false))
    }

    func completeLastStep() {
        guard let index = processingSteps.indices.last else { return }
        processingSteps[index].isComplete = true
        inputText = ""
    }
    
    func process(prompt: String) {
        Task {
            addStep("Sending request to Compiler")
            guard let functions: [Function<Parameters>] = try? await client.processFunction(prompt, for: state, using: "") else { return }
            completeLastStep()

            for function in functions {
                addStep(describe(function))
                execute(function)
                completeLastStep()
            }
        }
    }
}
