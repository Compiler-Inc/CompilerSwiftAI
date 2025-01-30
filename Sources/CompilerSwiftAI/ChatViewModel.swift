//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

@MainActor
@Observable
class ChatViewModel {
    var inputText = ""
    var isRecording = false
    var processingSteps: [ProcessingStep] = []

    var speechService: SpeechRecognitionService?

    func setupSpeechHandlers() {
        speechService?.onTranscript = { [weak self] transcript in
            Task { @MainActor in
                self?.inputText = transcript
            }
        }

        speechService?.onError = { [weak self] error in
            Task { @MainActor in
                print("Speech recognition error: \(error.localizedDescription)")
                self?.isRecording = false
            }
        }

        // Directly observe isRecording
        if let service = speechService {
            isRecording = service.isRecording
        }
    }

    func toggleRecording() {
        if isRecording {
            speechService?.stopRecording()
        } else {
            try? speechService?.startRecording()
        }
        // Update our local isRecording state
        if let service = speechService {
            isRecording = service.isRecording
        }
    }

    func addStep(_ description: String) {
        processingSteps.append(ProcessingStep(text: description, isComplete: false))
    }

    func completeLastStep() {
        guard let index = processingSteps.indices.last else { return }
        processingSteps[index].isComplete = true
    }
}
