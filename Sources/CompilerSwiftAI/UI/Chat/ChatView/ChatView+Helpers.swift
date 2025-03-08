import SwiftUI
import Combine

extension ChatView {
    @ViewBuilder
    func makeInputView() -> some View {
        ChatInputView(onAttachPhotos: {}, onAttachFiles: {}, onSendTap: { _ in }, dismissKeyboard: Just(()).eraseToAnyPublisher(), isLoading: .constant(false))
//        switch inputType {
//        case .text:
//            makeTextOnlyInput()
//        case .voice:
//            makeVoiceOnlyInput()
//        case .combined:
//            makeCombinedInput()
//        }
    }

    func makeTextOnlyInput() -> some View {
        GrowingTextField(
            placeholder: style.inputFieldPlaceholder,
            text: viewModel.userInputBinding,
            textColor: style.inputFieldTextColor,
            backgroundColor: style.inputFieldBackgroundColor,
            cornerRadius: style.inputFieldCornerRadius,
            padding: style.inputFieldPadding,
            onSubmit: sendCurrentInput,
            style: style
        ) {
            if !viewModel.userInputBinding.wrappedValue.isEmpty {
                makeSendButton()
            }
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, 8)
    }

    func makeVoiceOnlyInput() -> some View {
        makeVoiceButton()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, 8)
    }

    func makeCombinedInput() -> some View {
        GrowingTextField(
            placeholder: style.inputFieldPlaceholder,
            text: viewModel.userInputBinding,
            textColor: style.inputFieldTextColor,
            backgroundColor: style.inputFieldBackgroundColor,
            cornerRadius: style.inputFieldCornerRadius,
            padding: style.inputFieldPadding,
            onSubmit: sendCurrentInput,
            style: style
        ) {
            if viewModel.userInputBinding.wrappedValue.isEmpty {
                makeVoiceButton()
            } else {
                makeSendButton()
            }
        }
        .padding(.horizontal, style.horizontalPadding)
        .padding(.vertical, 8)
    }

    func makeVoiceButton() -> some View {
        Button {
            viewModel.toggleRecording()
        } label: {
            (isRecording ? style.voiceButtonActiveImage : style.voiceButtonImage)
                .font(.system(size: style.inputButtonSize * 0.8))
                .foregroundStyle(isRecording ? style.voiceButtonActiveTint : style.voiceButtonTint)
                .frame(width: style.inputButtonSize, height: style.inputButtonSize)
        }
        .disabled(viewModel.isStreaming)
    }

    func makeSendButton() -> some View {
        Button(action: sendCurrentInput) {
            style.sendButtonImage
                .font(.system(size: style.inputButtonSize * 0.8))
                .foregroundStyle(style.sendButtonTint)
                .frame(width: style.inputButtonSize, height: style.inputButtonSize)
        }
        .disabled(viewModel.userInputBinding.wrappedValue.isEmpty || viewModel.isStreaming)
    }
}
