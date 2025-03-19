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
    
    /// The provider of the model
    public let provider: ModelProvider
    
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
    
    /// Tools (including functions) that the model may call.
    public let tools: [Tool]?
    
    /// Controls which (if any) function is called by the model.
    public let toolChoice: ToolChoice?
    
    // MARK: - Initialization

    public init(
        messages: [Message],
        model: String,
        provider: ModelProvider,
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
        user: String? = nil,
        tools: [Tool]? = nil,
        toolChoice: ToolChoice? = nil
    ) {
        self.messages = messages
        self.model = model
        self.provider = provider
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
        self.tools = tools
        self.toolChoice = toolChoice
    }

    // MARK: - DTO Conversion

    func toDTO(stream: Bool) -> CompletionRequestDTO {
        CompletionRequestDTO(
            messages: messages.map { $0.toDTO() },
            model: model,
            provider: provider.rawValue,
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
            user: user,
            tools: tools?.map { $0.toDTO() },
            toolChoice: toolChoice?.toDTO()
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
    
    /// A tool that can be used by the model
    struct Tool {
        /// The type of the tool. Currently, only function is supported.
        let type: String
        let function: Function
        
        init(function: Function) {
            self.type = "function"
            self.function = function
        }
        
        func toDTO() -> CompletionRequestDTO.Tool {
            CompletionRequestDTO.Tool(function: function.toDTO())
        }
    }

    /// A function that can be called by the model
    struct Function {
        /// The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
        let name: String
        /// A description of what the function does, used by the model to choose when and how to call the function.
        let description: String?
        /// The parameters the functions accepts, described as a JSON Schema object.
        let parameters: [String: Any]?
        /// Whether to enable strict schema adherence when generating the function call.
        let strict: Bool?
        
        func toDTO() -> CompletionRequestDTO.Function {
            CompletionRequestDTO.Function(
                name: name,
                description: description,
                parameters: parameters,
                strict: strict
            )
        }
    }

    /// Controls which (if any) function is called by the model.
    enum ToolChoice {
        case none
        case auto
        case function(name: String)
        
        func toDTO() -> CompletionRequestDTO.ToolChoice {
            switch self {
            case .none:
                return .none
            case .auto:
                return .auto
            case .function(let name):
                return .function(name: name)
            }
        }
    }
}
