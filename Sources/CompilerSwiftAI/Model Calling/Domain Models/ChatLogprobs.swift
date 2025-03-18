//  Copyright © 2025 Compiler, Inc. All rights reserved.

import Foundation

// MARK: - Log Probabilities

/// Contains log probability details for the generated message.
public struct ChatLogprobs: Decodable, Sendable {
    /// An array of token log probability entries corresponding to parts of the message.
    public let content: [LogprobEntry]
}

/// Represents a single token entry with its log probability information.
public struct LogprobEntry: Decodable, Sendable {
    /// The token text.
    public let token: String
    /// The log probability of the token.
    public let logprob: Double
    /// The raw byte values for the token. This may be `null` for some tokens.
    public let bytes: [Int]?
    /// An array of the top log probability entries for this token.
    /// Each entry provides an alternative token candidate and its log probability.
    public let topLogprobs: [TopLogprobEntry]?
    
    enum CodingKeys: String, CodingKey {
        case token, logprob, bytes
        case topLogprobs = "top_logprobs"
    }
}

/// Represents an alternative token candidate with its associated log probability.
public struct TopLogprobEntry: Decodable, Sendable {
    /// The alternative token text.
    public let token: String
    /// The log probability of this alternative token.
    public let logprob: Double
    /// The raw byte values for the token. May be `null` if not available.
    public let bytes: [Int]?
}
