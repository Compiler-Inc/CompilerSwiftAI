//  Copyright 2025 Compiler, Inc. All rights reserved.

import OSLog

/// Primary interface for interacting with Compiler's Back End
public final actor CompilerClient {
    public struct Configuration {
        /// Current streaming configuration
        public var streamingChat: StreamConfiguration
        /// Whether to enable debug logging
        public var enableDebugLogging: Bool

        /// Initialize a new Configuration instance
        /// - Parameters:
        ///   - streamingChat: The streaming configuration to use for chat interactions, defaults to OpenAI GPT-4
        ///   - enableDebugLogging: Whether to enable detailed debug logging output, defaults to false
        public init(
            streamingChat: StreamConfiguration = .openAI(.gpt4o),
            enableDebugLogging: Bool = false
        ) {
            self.streamingChat = streamingChat
            self.enableDebugLogging = enableDebugLogging
        }
    }

    /// Application ID (retrievable from the Comiler Developer Dashboard)
    let appID: String

    private(set) var configuration: Configuration

    let baseURL: String = "https://backend.compiler.inc"
    let keychain: KeychainHelper = .standard
    let functionLogger: DebugLogger
    let modelLogger: DebugLogger
    let authLogger: DebugLogger

    /// Initialize the Compiler Client
    /// - Parameters:
    ///   - appID: Application ID (retrievable from the Comiler Developer Dashboard)
    ///   - configuration: Client configuration including streaming chat settings and debug options
    public init(
        appID: String,
        configuration: Configuration = Configuration()
    ) {
        self.appID = appID
        self.configuration = configuration
        functionLogger = DebugLogger(Logger.functionCalls, isEnabled: configuration.enableDebugLogging)
        modelLogger = DebugLogger(Logger.modelCalls, isEnabled: configuration.enableDebugLogging)
        authLogger = DebugLogger(Logger.auth, isEnabled: configuration.enableDebugLogging)
    }

    /// Update streaming chat configuration
    /// - Parameter update: Closure that takes an inout StreamConfiguration parameter
    public func updateStreamingChat(
        _ update: (inout StreamConfiguration) -> Void
    ) {
        update(&configuration.streamingChat)
    }

    /// Creates an immutable streaming session configuration
    /// This captures the current streaming configuration at a point in time
    public func makeStreamingSession() -> StreamConfiguration {
        configuration.streamingChat
    }

    /// Generate text using a completion request
    /// - Parameters:
    ///   - request: The completion request configuration
    ///   - model: The model configuration to use
    /// - Returns: The complete model response including tokens used, finish reason, etc.
    public func generateText(
        request: CompletionRequest,
        using model: StreamConfiguration
    ) async throws -> ChatCompletionResponse {
        try await makeModelCallWithResponse(
            using: model.metadata,
            request: request.toDTO(stream: false)
        )
    }

    /// Stream text generation using a completion request
    /// - Parameters:
    ///   - request: The completion request configuration
    ///   - model: The model configuration to use
    /// - Returns: An async stream of response chunks with metadata
    public func streamText(
        request: CompletionRequest,
        using model: StreamConfiguration
    ) async -> AsyncThrowingStream<ChatCompletionChunk, Error> {
        makeStreamingModelCall(using: model.metadata, request: request.toDTO(stream: true))
    }
}

private struct EmptyState: Encodable, Sendable {
    // Empty state for simplified function calls
}
