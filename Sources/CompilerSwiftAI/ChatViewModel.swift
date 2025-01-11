//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation
import AudioKit

@MainActor
@Observable
class ChatViewModel {
    
    var deepgram: DeepgramService?
    private let audioEngine = AudioEngine()
    private var promptTap: RawDataTap?
    private let silencer = Mixer()
    
    var processingSteps: [ProcessingStep] = []
    
    var manualCommand = ""
    
    init(deepgram: DeepgramService? = nil, promptTap: RawDataTap? = nil, processingSteps: [ProcessingStep] = [], manualCommand: String = "") {
        self.deepgram = deepgram
        self.promptTap = promptTap
        self.processingSteps = processingSteps
        self.manualCommand = manualCommand
        
        guard let input = audioEngine.input else {
            print("No input!")
            return
        }
        
        do {
            try Settings.setSession(category: .playAndRecord, with: [.defaultToSpeaker, .mixWithOthers])
            try Settings.session.setActive(true)
        } catch {
            print("error setting session: \(error)")
        }
        
        silencer.addInput(input)
        silencer.volume = 0
        audioEngine.output = silencer
        
    }
    
    func setupDeepgramHandlers() {
        
        guard let deepgram else {
            return
        }
        
        deepgram.onTranscriptReceived = { transcript in
            Task { @MainActor in
                if !self.manualCommand.isEmpty {
                    self.manualCommand += " "
                }
                self.manualCommand += transcript
            }
        }
        
        deepgram.onTranscriptionComplete = {
            Task { @MainActor in
                print("transcription complete")
            }
        }
    }
    
    public func addStep(_ text: String) {
        processingSteps.append(ProcessingStep(text: text, isComplete: false))
    }

    public func completeLastStep() {
        if let lastIndex = processingSteps.indices.last {
            processingSteps[lastIndex].isComplete = true
        }
    }
    
    func startRealtimeTranscription() {
        
        guard let deepgram else {
            print("No deepgram")
            return
        }
        
        guard let input = audioEngine.input else {
            print("No input!")
            return
        }

        
        do {
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error)")
            return
        }
        
        promptTap = RawDataTap(input, bufferSize: 4096) { buffer in
            deepgram.sendAudioData(buffer)
        }
        promptTap?.start()
        
        // Start WebSocket connection
        deepgram.startRealtimeTranscription()
    }
    
    func stopRealtimeTranscription() {
        
        guard let deepgram else {
            print("No deepgram")
            return
        }
        
        promptTap?.stop()
        promptTap = nil
        deepgram.stopRealtimeTranscription()
        audioEngine.stop()
    }
    
}
