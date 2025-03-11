//  Copyright © 2025 Compiler, Inc. All rights reserved.

@testable import CompilerSwiftAI
import Testing
import Foundation

private let chatCompletionResponseJSON = """
{
  "id": "chatcmpl-B9iGsDgVYG7AtBWHtvilaIxOSZhdN",
  "object": "chat.completion",
  "created": 1741654830,
  "model": "gpt-4o-mini-2024-07-18",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Hello! How can I assist you today?",
        "refusal": null
      },
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 10,
    "total_tokens": 18,
    "prompt_tokens_details": {
      "cached_tokens": 0,
      "audio_tokens": 0
    },
    "completion_tokens_details": {
      "reasoning_tokens": 0,
      "audio_tokens": 0,
      "accepted_prediction_tokens": 0,
      "rejected_prediction_tokens": 0
    }
  },
  "service_tier": "default",
  "system_fingerprint": "fp_06737a9306"
}
"""

private let anthropicCompletionResponseJSON = """
{
  "id": "msg_01LU6ji87zCTYCMDFDsHJEX9",
  "object": "chat_completion",
  "created": 1741654921,
  "model": "claude-3-7-sonnet-20250219",
  "provider": "anthropic",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Hello! How can I assist you today? Whether you have a question, need information, or just want to chat, I'm here to help. What would you like to talk about?"
      },
      "index": 0,
      "logprobs": null,
      "finish_reason": "end_turn"
    }
  ],
  "usage": {
    "prompt_tokens": 8,
    "completion_tokens": 41,
    "total_tokens": 49
  }
}
"""

private let chatCompletionChunkJSON = """
{
  "id": "chatcmpl-123",
  "object": "chat.completion.chunk",
  "created": 1677652288,
  "model": "gpt-4-0125-preview",
  "system_fingerprint": "fp_44709d6fcb",
  "choices": [{
    "index": 0,
    "delta": {
      "role": "assistant",
      "content": "Hello"
    },
    "finish_reason": null
  }]
}
"""

private let googleCompletionResponseJSON = """
{
  "id": "portkey-5e9db7af-d3fd-48cc-947f-a6e7f558cfd2",
  "object": "chat_completion",
  "created": 1741655050,
  "model": "gemini-2.0-flash",
  "provider": "google",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "Hello! How can I help you today?\\n"
      },
      "index": 0,
      "finish_reason": "STOP"
    }
  ],
  "usage": {
    "prompt_tokens": 1,
    "completion_tokens": 10,
    "total_tokens": 11
  }
}
"""


@Test func testChatCompletionResponseDecoding() async throws {
    // When we decode the JSON string
    let jsonData = Data(chatCompletionResponseJSON.utf8)
    let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
    
    // Then we expect all fields to match
    #expect(response.id == "chatcmpl-B9iGsDgVYG7AtBWHtvilaIxOSZhdN")
    #expect(response.object == "chat.completion")
    #expect(response.created == 1741654830)
    #expect(response.model == "gpt-4o-mini-2024-07-18")
    #expect(response.systemFingerprint == "fp_06737a9306")
    #expect(response.choices.count == 1)
    #expect(response.choices[0].message.role == ChatRole.assistant)
    #expect(response.choices[0].message.content == "Hello! How can I assist you today?")
    #expect(response.choices[0].message.refusal == nil)
    #expect(response.usage?.promptTokens == 8)
    #expect(response.usage?.completionTokens == 10)
    #expect(response.usage?.totalTokens == 18)
    #expect(response.serviceTier == "default")
    
    // Check token details
    #expect(response.usage?.promptTokensDetails?.cachedTokens == 0)
    #expect(response.usage?.completionTokensDetails?.reasoningTokens == 0)
    #expect(response.usage?.completionTokensDetails?.acceptedPredictionTokens == 0)
    #expect(response.usage?.completionTokensDetails?.rejectedPredictionTokens == 0)
}

@Test func testAnthropicCompletionResponseDecoding() async throws {
    // When we decode the JSON string
    let jsonData = Data(anthropicCompletionResponseJSON.utf8)
    let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
    
    // Then we expect all fields to match
    #expect(response.id == "msg_01LU6ji87zCTYCMDFDsHJEX9")
    #expect(response.object == "chat_completion")
    #expect(response.created == 1741654921)
    #expect(response.model == "claude-3-7-sonnet-20250219")
    #expect(response.choices.count == 1)
    #expect(response.choices[0].message.role == ChatRole.assistant)
    #expect(response.choices[0].message.content == "Hello! How can I assist you today? Whether you have a question, need information, or just want to chat, I'm here to help. What would you like to talk about?")
    #expect(response.choices[0].finishReason == "end_turn")
    #expect(response.usage?.promptTokens == 8)
    #expect(response.usage?.completionTokens == 41)
    #expect(response.usage?.totalTokens == 49)
}

@Test func testGoogleCompletionResponseDecoding() async throws {
    // When we decode the JSON string
    let jsonData = Data(googleCompletionResponseJSON.utf8)
    let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: jsonData)
    
    // Then we expect all fields to match
    #expect(response.id == "portkey-5e9db7af-d3fd-48cc-947f-a6e7f558cfd2")
    #expect(response.object == "chat_completion")
    #expect(response.created == 1741655050)
    #expect(response.model == "gemini-2.0-flash")
    #expect(response.choices.count == 1)
    #expect(response.choices[0].message.role == ChatRole.assistant)
    #expect(response.choices[0].message.content == "Hello! How can I help you today?\n")
    #expect(response.choices[0].finishReason == "STOP")
    #expect(response.usage?.promptTokens == 1)
    #expect(response.usage?.completionTokens == 10)
    #expect(response.usage?.totalTokens == 11)
}

@Test func testChatCompletionChunkDecoding() async throws {
    // Given a JSON file for chat completion chunk
    let jsonData = Data(chatCompletionChunkJSON.utf8)
    
    // When we decode it
    let chunk = try JSONDecoder().decode(ChatCompletionChunk.self, from: jsonData)
    
    // Then we expect all fields to match
    #expect(chunk.id == "chatcmpl-123")
    #expect(chunk.object == "chat.completion.chunk")
    #expect(chunk.created == 1677652288)
    #expect(chunk.model == "gpt-4-0125-preview")
    #expect(chunk.systemFingerprint == "fp_44709d6fcb")
    #expect(chunk.choices.count == 1)
    #expect(chunk.choices[0].delta.role == ChatRole.assistant)
    #expect(chunk.choices[0].delta.content == "Hello")
}

