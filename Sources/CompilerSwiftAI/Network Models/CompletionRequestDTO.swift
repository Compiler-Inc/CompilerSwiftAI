//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

/// A request body for generating completions with configurable parameters.
/// This struct encodes to JSON and maps its properties to the keys expected by the API.
struct CompletionRequestDTO: Encodable {
    
    // MARK: - Required
    
    /// The list of messages comprising the conversation so far.
    let messages: [MessageDTO]
    
    /// ID of the model to use
    let model: String
    
    /// The provider of the model
    let provider: String
    
    // MARK: - Optional Parameters with Defaults
    
    /// Whether to store the output for model distillation or evals.
    /// Default is false.
    let store: Bool?
    
    /// A value between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency.
    /// Default is 0.
    let frequencyPenalty: Double?
    
    /// Modify the likelihood of specified tokens appearing in the completion.
    let logitBias: [String: Int]?
    
    /// Whether to return log probabilities of the output tokens.
    /// Default is false.
    let logprobs: Bool?
    
    /// The maximum number of tokens to generate in the chat completion.
    let maxCompletionTokens: Int?
    
    /// The number of chat completion choices to generate.
    /// Default is 1.
    let n: Int?
    
    /// Number between -2.0 and 2.0. Positive values penalize tokens based on whether they appear in the text so far.
    /// Default is 0.
    let presencePenalty: Double?
    
    /// Optional seed for deterministic sampling.
    let seed: Int?
    
    /// Up to 4 sequences where the API will stop generating further tokens.
    let stop: StopSequence?
    
    /// Whether to stream back partial progress as data-only server-sent events.
    /// Default is false.
    let stream: Bool?
    
    /// Controls randomness in sampling (between 0 and 2).
    /// Default is 1.
    let temperature: Double?
    
    /// An alternative to sampling with temperature (between 0 and 1).
    /// Default is 1.
    let topP: Double?
    
    /// A unique identifier representing your end user.
    let user: String?
    
    /// Tools (including functions) that the model may call.
    let tools: [Tool]?
    
    /// Controls which (if any) function is called by the model.
    /// Can be "none", "auto", or a FunctionCall object.
    let toolChoice: ToolChoice?

    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case messages, model, provider, store
        case frequencyPenalty = "frequency_penalty"
        case logitBias = "logit_bias"
        case logprobs
        case maxCompletionTokens = "max_completion_tokens"
        case n
        case presencePenalty = "presence_penalty"
        case seed, stop, stream
        case temperature
        case topP = "top_p"
        case user
        case tools
        case toolChoice = "tool_choice"
    }
    
    /// Initialize a new completion request with the given parameters.
    init(
        messages: [MessageDTO],
        model: String,
        provider: String,
        store: Bool? = false,
        frequencyPenalty: Double? = 0,
        logitBias: [String: Int]? = nil,
        logprobs: Bool? = false,
        maxCompletionTokens: Int? = nil,
        n: Int? = 1,
        presencePenalty: Double? = 0,
        seed: Int? = nil,
        stop: StopSequence? = nil,
        stream: Bool? = false,
        temperature: Double? = 1,
        topP: Double? = 1,
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
        self.stream = stream
        self.temperature = temperature
        self.topP = topP
        self.user = user
        self.tools = tools
        self.toolChoice = toolChoice
    }
    
    func copy(
        messages: [MessageDTO]? = nil,
        model: String? = nil,
        provider: String? = nil,
        store: Bool? = nil,
        frequencyPenalty: Double? = nil,
        logitBias: [String: Int]? = nil,
        logprobs: Bool? = nil,
        maxCompletionTokens: Int? = nil,
        n: Int? = nil,
        presencePenalty: Double? = nil,
        seed: Int? = nil,
        stop: StopSequence? = nil,
        stream: Bool? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        user: String? = nil,
        tools: [Tool]? = nil,
        toolChoice: ToolChoice? = nil
    ) -> CompletionRequestDTO {
        CompletionRequestDTO(
            messages: messages ?? self.messages,
            model: model ?? self.model,
            provider: provider ?? self.provider,
            store: store ?? self.store,
            frequencyPenalty: frequencyPenalty ?? self.frequencyPenalty,
            logitBias: logitBias ?? self.logitBias,
            logprobs: logprobs ?? self.logprobs,
            maxCompletionTokens: maxCompletionTokens ?? self.maxCompletionTokens,
            n: n ?? self.n,
            presencePenalty: presencePenalty ?? self.presencePenalty,
            seed: seed ?? self.seed,
            stop: stop ?? self.stop,
            stream: stream ?? self.stream,
            temperature: temperature ?? self.temperature,
            topP: topP ?? self.topP,
            user: user ?? self.user,
            tools: tools ?? self.tools,
            toolChoice: toolChoice ?? self.toolChoice
        )
    }
}

extension CompletionRequestDTO {
    /// A type for the stop sequences, which can be a single string or an array of strings.
    /// When one of these sequences is encountered during generation, the API stops generating further tokens.
    enum StopSequence: Encodable {
        case string(String)
        case strings([String])
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .strings(let values):
                try container.encode(values)
            }
        }
    }
}

extension CompletionRequestDTO {
    /// A tool that can be used by the model.
    struct Tool: Encodable {
        /// The type of the tool. Currently, only function is supported.
        let type: String
        let function: Function
        
        init(function: Function) {
            self.type = "function"
            self.function = function
        }
    }

    /// A function that can be called by the model.
    struct Function: Encodable {
        /// The name of the function to be called. Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum length of 64.
        let name: String
        /// A description of what the function does, used by the model to choose when and how to call the function.
        let description: String?
        /// The parameters the functions accepts, described as a JSON Schema object.
        /// Omitting parameters defines a function with an empty parameter list.
        let parameters: [String: Any]?
        /// Whether to enable strict schema adherence when generating the function call.
        /// If set to true, the model will follow the exact schema defined in the parameters field.
        let strict: Bool?

        enum CodingKeys: String, CodingKey {
            case name, description, parameters, strict
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(description, forKey: .description)
            
            // Encode parameters as raw JSON if provided
            if let params = parameters {
                let jsonData = try JSONSerialization.data(withJSONObject: params)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                try container.encode(jsonString, forKey: .parameters)
            }
            
            try container.encodeIfPresent(strict, forKey: .strict)
        }
    }

    /// Controls which (if any) function is called by the model.
    enum ToolChoice: Encodable {
        case none
        case auto
        case function(name: String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .none:
                try container.encode("none")
            case .auto:
                try container.encode("auto")
            case .function(let name):
                let dict: [String: Any] = ["type": "function", "function": ["name": name]]
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
                try container.encode(jsonString)
            }
        }
    }
}
