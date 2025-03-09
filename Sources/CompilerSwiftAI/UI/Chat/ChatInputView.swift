//
//  SwiftUIView.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import Combine
import SwiftUI

struct ChatInputView: View {
    @State private var text: String = ""

    private let onAttachPhotos: () -> Void
    private let onAttachFiles: () -> Void

    private let onSendTap: (String) -> Void

    @FocusState private var isFocused: Bool

    private let dismissKeyboard: AnyPublisher<Void, Never>

    @Binding private var isLoading: Bool

    init(
        text: String = "",
        onAttachPhotos: @escaping () -> Void,
        onAttachFiles: @escaping () -> Void,
        onSendTap: @escaping (String) -> Void,
        dismissKeyboard: AnyPublisher<Void, Never>,
        isLoading: Binding<Bool>
    ) {
        self.text = text
        self.onAttachPhotos = onAttachPhotos
        self.onAttachFiles = onAttachFiles
        self.onSendTap = onSendTap
        self.dismissKeyboard = dismissKeyboard
        self._isLoading = isLoading
    }

    var body: some View {
        VStack {
            TextField(text: $text, prompt: Text("Chat"), axis: .vertical, label: {})
                .focused($isFocused)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.leading, 4)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .onReceive(dismissKeyboard) {
                    isFocused = false
                }

            ChatInputFieldAccessoriesView(
                onSendTap: {
                    withAnimation {
                        onSendTap(text)
                        text = ""
                        isFocused = false
                    }
                },
                onAttachPhotos: onAttachPhotos,
                onAttachFiles: onAttachFiles,
                text: $text,
                isLoading: $isLoading
            )
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
        .background(Color.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    ChatInputView(
        onAttachPhotos: {},
        onAttachFiles: {},
        onSendTap: { _ in },
        dismissKeyboard: Just(()).eraseToAnyPublisher(),
        isLoading: .constant(false)
    )
    .padding()
    .frame(width: 400, height: 200)
    .background(.black)
}

#Preview {
    ChatInputView(
        onAttachPhotos: {},
        onAttachFiles: {},
        onSendTap: { _ in },
        dismissKeyboard: Just(()).eraseToAnyPublisher(),
        isLoading: .constant(true)
    )
    .padding()
    .frame(width: 400, height: 200)
    .background(.black)
}

