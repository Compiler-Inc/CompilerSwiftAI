//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct TextInputView: View {
    
    @Bindable var model: ChatViewModel
    var process: (String) -> ()
        
    var body: some View {
        // Text Input Area
        VStack(spacing: 8) {
            Text("Prompt")
                .foregroundStyle(DLMColors.primary75)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.manualCommand)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
            .frame(height: 100)
            .foregroundStyle(DLMColors.primary100)
            .scrollContentBackground(.hidden)
            .background(DLMColors.primary20)
            .cornerRadius(8)
            .tint(DLMColors.primary100)

            HStack {
                
                if let deepgram = model.deepgram {
                    Button {
                        model.startRealtimeTranscription()
                    } label: {
                        Image(systemName: deepgram.isListening ? "microphone.fill" : "microphone")
                            .padding(.vertical, 8)
                            .frame(width: 40)
                            .background(DLMColors.dlmGradient)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    model.stopRealtimeTranscription()
                    process(model.manualCommand)
                }) {
                    HStack {
                        Text("Submit")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(DLMColors.dlmGradient)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(model.manualCommand.isEmpty)
                .buttonStyle(.plain)
                
            }
        }
        .padding()
    }
}

#Preview {
    let model = ChatViewModel()
    TextInputView(model: model, process: { _ in })
}
