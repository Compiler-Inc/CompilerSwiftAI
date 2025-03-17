//
//  File.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/9/25.
//

import Foundation

// MARK: - Chat Completion Chunk Response

/// Represents a streamed chunk of a chat completion response.
/// Each chunk has the same `id`, `created`, and other identifying fields, but the `choices` include incremental deltas.
public struct ChatCompletionChunk: Decodable, Sendable {
    /// A unique identifier for the chat completion. Each chunk shares the same ID.
    public let id: String
    /// The object type, which is always "chat.completion.chunk".
    public let object: String
    /// The Unix timestamp (in seconds) when the chat completion was created.
    public let created: Int
    /// The model used to generate the completion.
    public let model: String
    /// The service tier used for processing the request (if applicable).
    public let serviceTier: String?
    /// A fingerprint representing the backend configuration the model runs with.
    public let systemFingerprint: String?
    /// The list of chat completion choice chunks.
    public let choices: [ChatChunkChoice]
    /// Usage statistics for the completion request.
    /// This field is typically `null` for intermediate chunks and only provided on the final chunk when requested.
    public let usage: ChatUsage?
    
    enum CodingKeys: String, CodingKey {
        case id, object, created, model
        case serviceTier = "service_tier"
        case systemFingerprint = "system_fingerprint"
        case choices, usage
    }
}

/// Represents one choice chunk in a streamed chat completion response.
public struct ChatChunkChoice: Decodable, Sendable {
    /// The index of this choice in the returned array.
    public let index: Int
    /// The delta object representing incremental changes to the message.
    public let delta: ChatDelta
    /// Log probabilities for tokens (if available).
    public let logprobs: ChatLogprobs?
    /// The finish reason if the generation is complete (e.g., "stop"); otherwise `null`.
    public let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, delta, logprobs
        case finishReason = "finish_reason"
    }
}

/// Represents the incremental update (delta) for a chat message in a streamed response.
public struct ChatDelta: Decodable, Sendable {
    /// The role provided in the delta (may only be present in the first chunk).
    public let role: ChatRole?
    /// The content added in this chunk (if any).
    public let content: String?
}
