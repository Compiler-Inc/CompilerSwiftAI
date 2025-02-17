//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct TextInputView: View {
    @Bindable var model: FunctionChatViewModel
    var process: (String) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Prompt")
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $model.inputText)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            .frame(height: 100)
            .scrollContentBackground(.hidden)
            .cornerRadius(8)

            HStack {
                Button {
                    model.toggleRecording()
                } label: {
                    Image(systemName: model.isRecording ? "microphone.fill" : "microphone")
                        .padding(.vertical, 8)
                        .frame(width: 40)
                        .cornerRadius(8)
                }

                Button(action: {
//                    model.speechService?.stopRecording()
                    process(model.inputText)
                    model.inputText = ""
                }) {
                    HStack {
                        Text("Submit")
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
    let model = FunctionChatViewModel()
    TextInputView(model: model, process: { _ in })
}
