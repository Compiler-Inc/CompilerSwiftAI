import Speech
import SwiftUI
import Transcriber

import OSLog

// Example system prompt
let defaultSystemPrompt: String = """
You are a helpful AI Assistant. Be direct, concise, and friendly. Always format your responses in valid Markdown.
"""

@MainActor
@Observable
class ChatViewModel: Transcribable {
    public var isRecording = false
    public var transcribedText = ""
    public var rmsLevel: Float = 0.0
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

    // MARK: - Properties

    var errorMessage: String?
    private var _userInput = "" // Make private to control access
    var isStreaming = false
    var visibleMessageCount: Int = 15

    /// The messages rendered by SwiftUI
    private(set) var messages: [Message] = []

    // ChatDataSource conformance
    var userInput: String {
        get { _userInput }
        set {
            // Only update if actually different
            guard _userInput != newValue else { return }
            _userInput = newValue
        }
    }

    var userInputBinding: Binding<String> {
        Binding(
            get: { self._userInput },
            set: { newValue in
                // Only update if actually different
                guard self._userInput != newValue else { return }
                self._userInput = newValue
            }
        )
    }

    // MARK: - Private Properties

    private let chatHistory: ChatHistory
    private var messageStreamTask: Task<Void, Never>?

    /// Our service that talks to the backend
    let client: CompilerClient

    var systemPrompt: String

    /// Simple logger to show aggregator logs
    private let logger = Logger(subsystem: "ChatViewModel", category: "Aggregator")

    init(client: CompilerClient, systemPrompt: String = defaultSystemPrompt) {
        self.client = client
        self.systemPrompt = systemPrompt
        transcriber = Transcriber()

        chatHistory = ChatHistory(systemPrompt: systemPrompt)

        // Start observing messages from chatHistory
        messageStreamTask = Task.detached { [weak self] in
            guard let self = self else { return }
            await self.observeMessageStream()
        }
    }

    func toggleRecording() {
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
                    let stream = try await transcriber.startStream()
                    isRecording = true

                    for try await signal in stream {
                        switch signal {
                        case .rms(let float):
                            self.rmsLevel = float
                        case .transcription(let string):
                            self._userInput = string
                        }
                    }

                    // Stream completed (silence detected), send the complete transcription
                    if !self._userInput.isEmpty {
                        sendMessage(self._userInput)
                        self._userInput = ""
                    }

                    isRecording = false
                } catch {
                    errorMessage = error.localizedDescription
                    isRecording = false
                }
            }
        }
    }

    // MARK: - Observe ChatHistory

    /// Continuously read `chatHistory.messagesStream` and publish changes to SwiftUI.
    private func observeMessageStream() async {
        logger.log("observeMessageStream started. Now waiting for new messages...")

        // Continuously receive updates from chatHistory
        for await newMessages in await chatHistory.messagesStream {
            // Avoid processing if task is cancelled
            guard !Task.isCancelled else { break }

            // Log how many messages we got
            logger.log("Received newMessages from actor, count = \(newMessages.count). Checking diff...")

            // Now actually publish these messages to SwiftUI
            logger.log("Publishing updated messages to SwiftUI. count=\(newMessages.count)")
            await MainActor.run {
                self.messages = newMessages
            }
        }

        logger.log("observeMessageStream completed or was cancelled.")
    }

    // MARK: - Send Message / Stream Handling

    func sendMessage(_ text: String) {
        Task.detached {
            self.logger.log("sendMessage initiated with text: \"\(text)\". Adding user message.")
            await self.chatHistory.addUserMessage(text)

            // Start streaming a new assistant response
            await self.chatHistory.beginStreamingResponse()

            // Mark UI as streaming
            await MainActor.run { self.isStreaming = true }

            var accumulated = ""
            do {
                // Grab all messages so far (user + history)
                let messagesSoFar = await self.chatHistory.messages
                self.logger.log("Calling service.streamModelResponse with \(messagesSoFar.count) messages.")

                // Get immutable streaming configuration
                let config = await self.client.makeStreamingSession()
                let stream = await self.client.streamModelResponse(using: config.metadata, messages: messagesSoFar)

                var chunkCount = 0
                for try await partialMessage in stream {
                    chunkCount += 1
                    accumulated = partialMessage.content

                    // Log each chunk size
                    self.logger.log("Chunk #\(chunkCount): partial content size=\(accumulated.count). Updating streaming message.")

                    // Update partial text in chatHistory
                    await self.chatHistory.updateStreamingMessage(accumulated)
                }

                // SSE finished
                self.logger.log("Streaming complete. Final content size=\(accumulated.count). Completing streaming message.")
                await self.chatHistory.completeStreamingMessage(accumulated)
            } catch {
                self.logger.error("❌ SSE stream error: \(error). Completing with partial content.")
                await self.chatHistory.completeStreamingMessage(accumulated)
            }

            // Done streaming
            await MainActor.run { self.isStreaming = false }
            self.logger.log("sendMessage completed. isStreaming set to false.")
        }
    }

    // MARK: - Clear Chat

    func clearChat() {
        logger.log("clearChat called. Clearing chat history.")
        Task.detached {
            await self.chatHistory.clearHistory()
        }
    }
}
