//  Copyright 2025 Compiler, Inc. All rights reserved.

import Foundation

/// Configuration for chat completions.
/// This is the domain model used by client code to configure completion requests.
public struct CompletionRequest {
    // MARK: - Required
    
    /// The list of messages comprising the conversation so far.
    public let messages: [Message]
    
    /// ID of the model to use
    public let model: String
    
    // MARK: - Optional Parameters
    
    /// Whether to store the output for model distillation or evals.
    public let store: Bool?
    
    /// A value between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency.
    public let frequencyPenalty: Double?
    
    /// Modify the likelihood of specified tokens appearing in the completion.
    public let logitBias: [String: Int]?
    
    /// Whether to return log probabilities of the output tokens.
    public let logprobs: Bool?
    
    /// The maximum number of tokens to generate in the chat completion.
    public let maxCompletionTokens: Int?
    
    /// The number of chat completion choices to generate.
    public let n: Int?
    
    /// Number between -2.0 and 2.0. Positive values penalize tokens based on whether they appear in the text so far.
    public let presencePenalty: Double?
    
    /// Optional seed for deterministic sampling.
    public let seed: Int?
    
    /// Up to 4 sequences where the API will stop generating further tokens.
    public let stop: StopSequence?
    
    /// Controls randomness in sampling (between 0 and 2).
    public let temperature: Double?
    
    /// An alternative to sampling with temperature (between 0 and 1).
    public let topP: Double?
    
    /// A unique identifier representing your end user.
    public let user: String?

    // MARK: - Initialization

    public init(
        messages: [Message],
        model: String,
        store: Bool? = nil,
        frequencyPenalty: Double? = nil,
        logitBias: [String: Int]? = nil,
        logprobs: Bool? = nil,
        maxCompletionTokens: Int? = nil,
        n: Int? = nil,
        presencePenalty: Double? = nil,
        seed: Int? = nil,
        stop: StopSequence? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        user: String? = nil
    ) {
        self.messages = messages
        self.model = model
        self.store = store
        self.frequencyPenalty = frequencyPenalty
        self.logitBias = logitBias
        self.logprobs = logprobs
        self.maxCompletionTokens = maxCompletionTokens
        self.n = n
        self.presencePenalty = presencePenalty
        self.seed = seed
        self.stop = stop
        self.temperature = temperature
        self.topP = topP
        self.user = user
    }

    // MARK: - DTO Conversion

    func toDTO(stream: Bool) -> CompletionRequestDTO {
        CompletionRequestDTO(
            messages: messages.map { $0.toDTO() },
            model: model,
            store: store,
            frequencyPenalty: frequencyPenalty,
            logitBias: logitBias,
            logprobs: logprobs,
            maxCompletionTokens: maxCompletionTokens,
            n: n,
            presencePenalty: presencePenalty,
            seed: seed,
            stop: stop?.toDTO(),
            stream: stream,
            temperature: temperature,
            topP: topP,
            user: user
        )
    }
}

// MARK: - Supporting Types

public extension CompletionRequest {
    /// A type for the stop sequences, which can be a single string or an array of strings.
    /// When one of these sequences is encountered during generation, the API stops generating further tokens.
    enum StopSequence {
        case string(String)
        case strings([String])

        // Convert to DTO
        func toDTO() -> CompletionRequestDTO.StopSequence {
            switch self {
            case .string(let value):
                return .string(value)
            case .strings(let values):
                return .strings(values)
            }
        }
    }
}
