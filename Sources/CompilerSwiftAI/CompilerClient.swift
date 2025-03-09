//  Copyright © 2025 Compiler, Inc. All rights reserved.

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
    let appID: UUID
    
    private(set) var configuration: Configuration

    internal let baseURL: String = "https://backend.compiler.inc"
    internal let keychain: KeychainHelper = KeychainHelper.standard
    internal let functionLogger: DebugLogger
    internal let modelLogger: DebugLogger
    internal let authLogger: DebugLogger
    
    /// Initialize the Compiler Client
    /// - Parameters:
    ///   - appID: Application ID (retrievable from the Comiler Developer Dashboard)
    ///   - configuration: Client configuration including streaming chat settings and debug options
    public init(
        appID: UUID, 
        configuration: Configuration = Configuration()
    ) {
        self.appID = appID
        self.configuration = configuration
        self.functionLogger = DebugLogger(Logger.functionCalls, isEnabled: configuration.enableDebugLogging)
        self.modelLogger = DebugLogger(Logger.modelCalls, isEnabled: configuration.enableDebugLogging)
        self.authLogger = DebugLogger(Logger.auth, isEnabled: configuration.enableDebugLogging)
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
    
    /// Generate text from a prompt using the specified model
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - model: The model configuration to use
    ///   - systemPrompt: Optional system prompt to set context
    /// - Returns: The complete model response including tokens used, finish reason, etc.
    public func generateText(
        prompt: String,
        using model: StreamConfiguration,
        systemPrompt: String? = nil
    ) async throws -> CompletionResponse {
        try await makeModelCallWithResponse(
            using: model.metadata,
            systemPrompt: systemPrompt,
            userPrompt: prompt
        )
    }
    
    /// Stream text generation from a prompt
    /// - Parameters:
    ///   - prompt: The input prompt
    ///   - model: The model configuration to use
    ///   - systemPrompt: Optional system prompt to set context
    /// - Returns: An async stream of response chunks with metadata
    public func streamText(
        prompt: String,
        using model: StreamConfiguration,
        systemPrompt: String? = nil
    ) async -> AsyncThrowingStream<String, Error> {
        let message = Message(role: .user, content: prompt)
        let messages = systemPrompt.map { [Message(role: .system, content: $0), message] } ?? [message]
        return makeStreamingModelCall(using: model.metadata, messages: messages)
    }
    
    /// Process a natural language command into structured function calls
    /// - Parameters:
    ///   - command: The natural language command to process
    /// - Returns: Array of functions with their parameters
    /// - Note: You must specify the Parameters type when calling this function, either through type annotation or explicit generic parameter:
    ///   ```swift
    ///   // Option 1: Type annotation
    ///   let functions: [Function<MyParameters>] = try await client.processFunctionCall("Add todo")
    ///
    ///   // Option 2: Explicit generic
    ///   let functions = try await client.processFunctionCall<MyParameters>("Add todo")
    ///   ```
    public func processFunctionCall<Parameters: Decodable & Sendable>(
        _ command: String
    ) async throws -> [Function<Parameters>] {
        // We use an empty state since this is the simplified version
        try await processFunction(command, for: EmptyState(), using: "")
    }
    
    public func processFunctionCallWithAPIKey<Parameters: Decodable & Sendable>(
        _ command: String
    ) async throws -> [Function<Parameters>] {
        // We use an empty state since this is the simplified version
        try await processFunction(command, for: EmptyState())
    }
}

private struct EmptyState: Encodable, Sendable {
    // Empty state for simplified function calls
}

