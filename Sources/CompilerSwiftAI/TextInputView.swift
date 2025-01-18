//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct TextInputView: View {
    
    @Bindable var model: ChatViewModel
    var process: (String) -> ()
        
    var body: some View {
        VStack(spacing: 8) {
            Text("Prompt")
                .foregroundStyle(DLMColors.primary75)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.inputText)
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
                Button {
                    model.toggleRecording()
                } label: {
                    Image(systemName: model.isRecording ? "microphone.fill" : "microphone")
                        .padding(.vertical, 8)
                        .frame(width: 40)
                        .background(DLMColors.dlmGradient)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    model.speechService?.stopRecording()
                    process(model.inputText)
                    model.inputText = ""
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
                .disabled(model.inputText.isEmpty)
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
