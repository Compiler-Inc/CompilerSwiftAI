import Speech
import AVFoundation

public actor SpeechRecognitionService {
    private let speechRecognizer: SFSpeechRecognizer
    private let audioEngine: AVAudioEngine
    
    // These actor‐isolated properties let us stop/cancel ongoing recognition:
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    public init(locale: Locale = Locale(identifier: "en-US")) {
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            fatalError("Could not create SFSpeechRecognizer for locale \(locale)")
        }
        self.speechRecognizer = recognizer
        self.audioEngine = AVAudioEngine()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error starting audio session: \(error.localizedDescription)")
        }
    }

    public func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    public func startRecordingStream() throws -> AsyncThrowingStream<String, Error> {
        // Cancel any existing recognition tasks
        recognitionTask?.cancel()
        recognitionTask = nil

        // Create a local request
        let localRequest = SFSpeechAudioBufferRecognitionRequest()
        localRequest.shouldReportPartialResults = true

        // Store it in actor property so stopRecording() can end it later
        recognitionRequest = localRequest

        // Install a tap on the audio engine *before* creating the stream
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Create local state for silence detection
        var isSilent = false
        var silenceStartTime = CFAbsoluteTimeGetCurrent()  // Initialize to now
        let silenceThreshold: Float = 0.001
        let silenceDuration: TimeInterval = 1.5
        var hasEndedAudio = false

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self, localRequest] buffer, _ in
            guard let self = self, !hasEndedAudio else { return }
            
            let rms = buffer.rms()
            let currentTime = CFAbsoluteTimeGetCurrent()
            
            if rms < silenceThreshold {
                if !isSilent {
                    isSilent = true
                    silenceStartTime = currentTime
                } else if !hasEndedAudio && (currentTime - silenceStartTime) >= silenceDuration {
                    hasEndedAudio = true
                    localRequest.endAudio()
                    // Call stopRecording here since we're done
                    Task { @MainActor in
                        await self.stopRecording()
                    }
                    return
                }
            } else {
                isSilent = false
            }
            
            localRequest.append(buffer)
        }

        // Start the audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Create and return the `AsyncThrowingStream`
        return AsyncThrowingStream<String, Error> { continuation in
            // Create a local recognition task
            let localTask = self.speechRecognizer.recognitionTask(with: localRequest) { result, error in
                // We only yield partial results or final if no error
                if let result {
                    continuation.yield(result.bestTranscription.formattedString)
                }
                // If there's an error or final result, finish the stream
                if let error {
                    continuation.finish(throwing: error)
                } else if result?.isFinal == true {
                    continuation.finish()
                }
            }

            // Store it in actor property so we can cancel it in stopRecording()
            self.recognitionTask = localTask
        }
    }

    public func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionTask = nil
        recognitionRequest = nil
    }
}

// Extension to calculate RMS
extension AVAudioPCMBuffer {
    func rms() -> Float {
        guard let channelData = self.floatChannelData else { return 0 }
        let channelCount = Int(self.format.channelCount)
        let frameLength = Int(self.frameLength)
        var sum: Float = 0
        
        // Sum squares of all samples from all channels
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength {
                let sample = data[frame]
                sum += sample * sample
            }
        }
        
        // Calculate RMS
        let avgSquare = sum / Float(frameLength * channelCount)
        return sqrt(avgSquare)
    }
}
