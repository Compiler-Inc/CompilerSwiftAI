import Foundation

// MARK: - Chat Completion Response

/// Represents a chat completion response returned by the API.
/// This object is used when the entire response is returned in one payload.
public struct ChatCompletionResponse: Decodable, Sendable {
    /// A unique identifier for the chat completion.
    public let id: String
    /// The object type, which is always "chat.completion".
    public let object: String
    /// The Unix timestamp (in seconds) of when the chat completion was created.
    public let created: Int
    /// The model used for generating the chat completion.
    public let model: String
    /// The service tier used for processing the request (if applicable).
    public let serviceTier: String?
    /// A fingerprint representing the backend configuration the model runs with.
    /// This can be used with the seed parameter to determine if backend changes may affect determinism.
    public let systemFingerprint: String?
    /// The list of chat completion choices returned by the model.
    public let choices: [ChatChoice]
    /// Usage statistics for the completion request.
    public let usage: ChatUsage?
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model
        case serviceTier = "service_tier"
        case systemFingerprint = "system_fingerprint"
        case choices, usage
    }
}

/// Represents one chat completion choice in the response.
public struct ChatChoice: Decodable, Sendable {
    /// The index of this completion choice in the returned array.
    public let index: Int
    /// The chat message generated for this choice.
    public let message: ChatMessage
    /// Log probabilities for tokens in the completion (if available).
    public let logprobs: ChatLogprobs?
    /// The reason why the generation stopped (e.g., "stop").
    public let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message, logprobs
        case finishReason = "finish_reason"
    }
}

/// Represents a chat message returned by the API.
public struct ChatMessage: Decodable, Sendable {
    /// The role of the message sender (for example, "assistant", "user", or "system").
    public let role: ChatRole
    /// The content of the message.
    public let content: String
    /// An optional refusal message (if applicable).
    public let refusal: String?
}

/// The role of a chat message.
public enum ChatRole: String, Decodable, Sendable {
    case system
    case user
    case assistant
}

// MARK: - Usage and Token Details

/// Contains usage statistics for the chat completion request.
public struct ChatUsage: Decodable, Sendable {
    /// Number of tokens in the prompt.
    public let promptTokens: Int
    /// Number of tokens generated in the completion.
    public let completionTokens: Int
    /// Total number of tokens used (prompt + completion).
    public let totalTokens: Int
    /// Breakdown of tokens used in the prompt.
    public let promptTokensDetails: PromptTokensDetails?
    /// Breakdown of tokens used in the completion.
    public let completionTokensDetails: CompletionTokensDetails?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptTokensDetails = "prompt_tokens_details"
        case completionTokensDetails = "completion_tokens_details"
    }
}

/// Detailed breakdown of tokens used in the prompt.
public struct PromptTokensDetails: Decodable, Sendable {
    /// Example field: number of cached tokens (if available).
    public let cachedTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
    }
}

/// Detailed breakdown of tokens used in the completion.
public struct CompletionTokensDetails: Decodable, Sendable {
    /// Number of tokens used for reasoning.
    public let reasoningTokens: Int?
    /// Number of tokens accepted as prediction.
    public let acceptedPredictionTokens: Int?
    /// Number of tokens rejected as prediction.
    public let rejectedPredictionTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case reasoningTokens = "reasoning_tokens"
        case acceptedPredictionTokens = "accepted_prediction_tokens"
        case rejectedPredictionTokens = "rejected_prediction_tokens"
    }
}
