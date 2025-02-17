//  Copyright © 2025 Compiler, Inc. All rights reserved.

import SwiftUI

struct TextInputView<AppState: Encodable & Sendable, Parameters: Decodable & Sendable>: View {
    var model: FunctionChatViewModel<AppState, Parameters>
    var process: (String) -> Void
    
    var userInputBinding: Binding<String> {
        Binding(
            get: { model.inputText },
            set: { newValue in
                // Only update if actually different
                guard model.inputText != newValue else { return }
                model.inputText = newValue
            }
        )
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Prompt")
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .topLeading) {
                TextEditor(text: userInputBinding)
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
                    process(model.inputText)
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
