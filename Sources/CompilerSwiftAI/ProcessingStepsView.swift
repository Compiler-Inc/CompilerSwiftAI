//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct ProcessingStepsView: View {
    var steps: [ProcessingStep]

    var body: some View {
        // Processing Steps Area
        VStack(alignment: .leading, spacing: 4) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(steps) { step in
                        HStack {
                            Text(step.text)
                                .foregroundColor(DLMColors.primary75)

                            Spacer()

                            if step.isComplete {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

#Preview {
    ProcessingStepsView(steps: [])
}

func sendMessage(_ text: String) {
    let userMessage = ChatMessage(role: .user, content: text, isComplete: true)
    messages.append(userMessage)
    
    Task {
        let assistantMessage = ChatMessage(role: .assistant, content: "", isComplete: false)
        messages.append(assistantMessage)
        scrollTarget = assistantMessage.id
        
        isStreaming = true
        
        let stream = await service.makeStreamingModelCall(
            systemPrompt: "You are a helpful AI Assistant",
            userPrompt: text,
            using: .openAI(.gpt4oMini)
        )
        
        do {
            for try await chunk in stream {
                // Log raw chunk with escaped characters
                print("📤 Received chunk (escaped):")
                print(chunk.unicodeScalars.map { "\\u{\(String(format: "%04x", $0.value))}" }.joined())
                
                if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                    // Simple concatenation - no manipulation of the chunk
                    messages[index].content += chunk
                    
                    // Log current state with escaped characters every 500 chars
                    if messages[index].content.count % 500 == 0 {
                        print("📑 Message length: \(messages[index].content.count)")
                        print("📑 Last 100 chars (escaped):")
                        let lastChars = String(messages[index].content.suffix(100))
                        print(lastChars.unicodeScalars.map { "\\u{\(String(format: "%04x", $0.value))}" }.joined())
                    }
                }
            }
            
            if let index = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages[index].isComplete = true
                print("✅ Final message length: \(messages[index].content.count)")
            }
        } catch {
            print("❌ Stream error: \(error)")
        }
        
        isStreaming = false
    }
}
