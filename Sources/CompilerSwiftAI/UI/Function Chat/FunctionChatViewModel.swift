//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Speech
import SwiftUI
import Transcriber

@MainActor
@Observable
class FunctionChatViewModel<AppState: Encodable & Sendable, Parameters: Decodable & Sendable>: Transcribable {
    public var isRecording = false
    public var transcribedText = ""
    public var authStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    public var error: Error?

    public let transcriber: Transcriber?
    private var recordingTask: Task<Void, Never>?

    // Required protocol methods
    public func requestAuthorization() async throws {
        guard let transcriber else {
            throw TranscriberError.noRecognizer
        }
        authStatus = await transcriber.requestAuthorization()
        guard authStatus == .authorized else {
            throw TranscriberError.notAuthorized
        }
    }

    public func toggleRecording() {
        guard let transcriber else {
            error = TranscriberError.noRecognizer
            return
        }

        if isRecording {
            recordingTask?.cancel()
            recordingTask = nil
            isRecording = false
        } else {
            recordingTask = Task {
                do {
                    isRecording = true
                    let stream = try await transcriber.startStream()

                    for try await signal in stream {
                        switch signal {
                        case let .rms(float):
                            print("float: \(float)")
                        case let .transcription(string):
                            inputText = string
                        }
                    }

                    isRecording = false
                } catch {
                    self.error = error
                    isRecording = false
                }
            }
        }
    }

    var inputText = ""
    var processingSteps: [ProcessingStep] = []

    var state: AppState
    var client: CompilerClient
    var describe: (Function<Parameters>) -> String
    var execute: (Function<Parameters>) -> Void

    init(state: AppState, client: CompilerClient, describe: @escaping (Function<Parameters>) -> String, execute: @escaping (Function<Parameters>) -> Void) {
        transcriber = Transcriber()
        self.state = state
        self.client = client
        self.describe = describe
        self.execute = execute
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
