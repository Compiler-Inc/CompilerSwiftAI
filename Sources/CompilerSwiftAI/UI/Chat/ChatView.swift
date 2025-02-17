import SwiftUI
import Observation
import MarkdownUI

// MARK: - Chat Container
@MainActor
public struct ChatView<DataSource: ChatDataSource, Style: ChatViewStyle>: View {
    let dataSource: DataSource
    var style: Style
    let inputType: ChatInputType
    @State var showScrollButton = false
    @State var scrollViewProxy: ScrollViewProxy?
    @State var isRecording = false
    
    // Bubble styling properties
    var userBubbleColor: Color = .blue
    var assistantBubbleColor: Color = .clear
    var userTextColor: Color = .white
    var assistantTextColor: Color = .black
    var userTypingColor: Color = .white.opacity(0.7)
    var assistantTypingColor: Color = .gray.opacity(0.7)
    var bubbleCornerRadius: CGFloat = 16
    var bubblePadding: EdgeInsets?
    
    // Markdown theme customization
    var markdownTheme: ((Theme) -> Theme)?
    
    var visibleMessages: [Message] {
        // First filter out system messages
        let userAndAssistantMessages = dataSource.messages.filter { $0.role != .system }
        
        // Then apply our visible message count limit
        let startIndex = max(0, userAndAssistantMessages.count - dataSource.visibleMessageCount)
        return Array(userAndAssistantMessages[startIndex...])
    }
    
    public init(
        dataSource: DataSource,
        inputType: ChatInputType = .combined,
        style: Style = DefaultChatViewStyle()
    ) {
        self.dataSource = dataSource
        self.inputType = inputType
        self.style = style
    }
    
    func defaultMarkdownTheme(for message: Message) -> Theme {
        let foregroundColor = message.role == .user ? userTextColor : assistantTextColor
        
        return Theme()
            .text {
                ForegroundColor(foregroundColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                ForegroundColor(foregroundColor)
            }
            .codeBlock { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                            ForegroundColor(foregroundColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(foregroundColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }
            .strong {
                FontWeight(.bold)
            }
            .emphasis {
                FontStyle(.italic)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: .em(1), bottom: .em(0.5))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.5))
                        ForegroundColor(foregroundColor)
                    }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.8), bottom: .em(0.4))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.3))
                        ForegroundColor(foregroundColor)
                    }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.6), bottom: .em(0.3))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.1))
                        ForegroundColor(foregroundColor)
                    }
            }
            .list { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.5))
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.25))
            }
            .bulletedListMarker { configuration in
                Text("•")
                    .foregroundColor(foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .numberedListMarker { configuration in
                Text("\(configuration.itemNumber).")
                    .foregroundColor(foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
    }
    
    // MARK: - Input Views
    
    @ViewBuilder
    func makeInputView() -> some View {
        switch inputType {
        case .text:
            makeTextOnlyInput()
        case .voice:
            makeVoiceOnlyInput()
        case .combined:
            makeCombinedInput()
        }
    }
    
    func makeTextOnlyInput() -> some View {
        GrowingTextField(
            placeholder: style.inputFieldPlaceholder,
            text: dataSource.userInputBinding,
            textColor: style.inputFieldTextColor,
            backgroundColor: style.inputFieldBackgroundColor,
            cornerRadius: style.inputFieldCornerRadius,
            padding: style.inputFieldPadding,
            onSubmit: sendCurrentInput,
            style: style
        ) {
            if !dataSource.userInputBinding.wrappedValue.isEmpty {
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
            text: dataSource.userInputBinding,
            textColor: style.inputFieldTextColor,
            backgroundColor: style.inputFieldBackgroundColor,
            cornerRadius: style.inputFieldCornerRadius,
            padding: style.inputFieldPadding,
            onSubmit: sendCurrentInput,
            style: style
        ) {
            if dataSource.userInputBinding.wrappedValue.isEmpty {
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
            dataSource.toggleRecording()
        } label: {
            (isRecording ? style.voiceButtonActiveImage : style.voiceButtonImage)
                .font(.system(size: style.inputButtonSize * 0.8))
                .foregroundStyle(isRecording ? style.voiceButtonActiveTint : style.voiceButtonTint)
                .frame(width: style.inputButtonSize, height: style.inputButtonSize)
        }
        .disabled(dataSource.isStreaming)
    }
    
    func makeSendButton() -> some View {
        Button(action: sendCurrentInput) {
            style.sendButtonImage
                .font(.system(size: style.inputButtonSize * 0.8))
                .foregroundStyle(style.sendButtonTint)
                .frame(width: style.inputButtonSize, height: style.inputButtonSize)
        }
        .disabled(dataSource.userInputBinding.wrappedValue.isEmpty || dataSource.isStreaming)
    }
    
    func sendCurrentInput() {
        guard !dataSource.userInputBinding.wrappedValue.isEmpty else { return }
        let input = dataSource.userInputBinding.wrappedValue
        dataSource.userInputBinding.wrappedValue = ""
        dataSource.sendMessage(input)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: dataSource.spacing) {
                            ForEach(visibleMessages) { message in
                                ChatBubble(message: message)
                                    .bubbleBackground(
                                        RoundedRectangle(cornerRadius: bubbleCornerRadius),
                                        color: message.role == .user ? userBubbleColor : assistantBubbleColor
                                    )
                                    .bubbleForegroundColor(message.role == .user ? userTextColor : assistantTextColor)
                                    .typingIndicator(
                                        color: message.role == .user ? userTypingColor : assistantTypingColor
                                    )
                                    .if(bubblePadding != nil) { view in
                                        view.bubblePadding(bubblePadding!)
                                    }
                                    .markdownTheme(markdownTheme?(defaultMarkdownTheme(for: message)) ?? defaultMarkdownTheme(for: message))
                                    .id(message.id)
                                    .transition(.opacity)
                            }
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.horizontal, style.horizontalPadding)
                    }
                    .coordinateSpace(name: "scroll")
                    .scrollIndicators(.hidden)
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                }
                
                if showScrollButton {
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            scrollViewProxy?.scrollTo("bottom", anchor: .bottom)
                        }
                        showScrollButton = false
                    } label: {
                        style.scrollButtonImage
                            .font(.title)
                            .foregroundStyle(style.scrollButtonTint)
                            .background(Circle().fill(style.scrollButtonBackgroundColor))
                            .shadow(radius: style.scrollButtonShadowRadius)
                    }
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            makeInputView()
        }
    }
}

// MARK: - View Extensions

extension View {
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
}

// MARK: - Chat Container Modifiers

