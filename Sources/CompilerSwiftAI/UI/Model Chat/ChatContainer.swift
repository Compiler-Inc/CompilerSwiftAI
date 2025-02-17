import SwiftUI
import Observation
import MarkdownUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - Input Types

public enum ChatInputType {
    case text
    case voice
    case combined
}

// MARK: - Chat Container Style
public protocol ChatContainerStyle {
    var scrollButtonImage: Image { get set }
    var scrollButtonTint: Color { get set }
    var scrollButtonBackgroundColor: Color { get set }
    var scrollButtonShadowRadius: CGFloat { get set }
    var horizontalPadding: CGFloat { get set }
    
    // Input field styling
    var inputFieldBackgroundColor: Color { get set }
    var inputFieldTextColor: Color { get set }
    var inputFieldPlaceholder: String { get set }
    var inputFieldCornerRadius: CGFloat { get set }
    var inputFieldPadding: EdgeInsets { get set }
    
    // Common button styling
    var inputButtonSize: CGFloat { get set }
    var inputButtonPadding: CGFloat { get set }
    
    // Send button specific
    var sendButtonImage: Image { get set }
    var sendButtonTint: Color { get set }
    var sendButtonBackgroundColor: Color { get set }
    
    // Voice button specific
    var voiceButtonImage: Image { get set }
    var voiceButtonActiveImage: Image { get set }
    var voiceButtonTint: Color { get set }
    var voiceButtonActiveTint: Color { get set }
    var voiceButtonBackgroundColor: Color { get set }
    var voiceButtonActiveBackgroundColor: Color { get set }
}

public struct DefaultChatContainerStyle: ChatContainerStyle {
    public var scrollButtonImage: Image = Image(systemName: "arrow.down.circle.fill")
    public var scrollButtonTint: Color = .white
    public var scrollButtonBackgroundColor: Color = .blue
    public var scrollButtonShadowRadius: CGFloat = 4
    public var horizontalPadding: CGFloat = 16
    
    // Input field styling
    public var inputFieldBackgroundColor: Color = .gray.opacity(0.1)
    public var inputFieldTextColor: Color = .primary
    public var inputFieldPlaceholder: String = "Message"
    public var inputFieldCornerRadius: CGFloat = 20
    public var inputFieldPadding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 40)
    
    // Common button styling
    public var inputButtonSize: CGFloat = 28
    public var inputButtonPadding: CGFloat = 0
    
    // Send button specific
    public var sendButtonImage: Image = Image(systemName: "arrow.up.circle.fill")
    public var sendButtonTint: Color = .blue
    public var sendButtonBackgroundColor: Color = .clear
    
    // Voice button specific
    public var voiceButtonImage: Image = Image(systemName: "mic.circle.fill")
    public var voiceButtonActiveImage: Image = Image(systemName: "mic.circle.fill")
    public var voiceButtonTint: Color = .blue
    public var voiceButtonActiveTint: Color = .red
    public var voiceButtonBackgroundColor: Color = .clear
    public var voiceButtonActiveBackgroundColor: Color = .clear
    
    public init() {}
}

// MARK: - Growing TextField

private struct GrowingTextField: View {
    let placeholder: String
    @Binding var text: String
    let textColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let onSubmit: () -> Void
    let trailingContent: () -> AnyView
    let style: ChatContainerStyle
    
    init(
        placeholder: String,
        text: Binding<String>,
        textColor: Color,
        backgroundColor: Color,
        cornerRadius: CGFloat,
        padding: EdgeInsets,
        onSubmit: @escaping () -> Void,
        style: ChatContainerStyle,
        @ViewBuilder trailingContent: @escaping () -> some View
    ) {
        self.placeholder = placeholder
        self._text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onSubmit = onSubmit
        self.style = style
        self.trailingContent = { AnyView(trailingContent()) }
    }
    
    @State private var textViewHeight: CGFloat = 36  // Initial height
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: 0) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(height: max(36, textViewHeight))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .foregroundColor(textColor)
                    .onChange(of: text) { _, newValue in
                        #if os(iOS)
                        let size = (newValue as NSString).boundingRect(
                            with: CGSize(width: UIScreen.main.bounds.width - 100, height: .infinity),
                            options: [.usesFontLeading, .usesLineFragmentOrigin],
                            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                            context: nil
                        )
                        textViewHeight = min(120, max(36, size.height + 20))
                        #else
                        let size = (newValue as NSString).boundingRect(
                            with: CGSize(width: NSScreen.main?.frame.width ?? 800 - 100, height: .infinity),
                            options: [.usesFontLeading, .usesLineFragmentOrigin],
                            attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize)],
                            context: nil
                        )
                        textViewHeight = min(120, max(36, size.height + 20))
                        #endif
                    }
                    .overlay(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.gray)
                                .allowsHitTesting(false)
                                .padding(.leading, 4)
                        }
                    }
            }
            .padding(.trailing, style.inputButtonSize + 8)  // Increased spacing for larger button
            
            trailingContent()
                .padding(.trailing, 4)  // Small edge padding
                .padding(.bottom, 4)  // Add bottom padding to center vertically
        }
        .padding(EdgeInsets(
            top: padding.top,
            leading: padding.leading,
            bottom: padding.bottom,
            trailing: max(padding.trailing - style.inputButtonSize, 8)  // Ensure minimum trailing space
        ))
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .onSubmit(onSubmit)
    }
}

// MARK: - Chat Container

@MainActor
public struct ChatContainer<DataSource: ChatDataSource, Style: ChatContainerStyle>: View {
    private let dataSource: DataSource
    private var style: Style
    private let inputType: ChatInputType
    @State private var showScrollButton = false
    @State private var scrollViewProxy: ScrollViewProxy?
    @State private var isRecording = false
    
    // Bubble styling properties
    private var userBubbleColor: Color = .blue
    private var assistantBubbleColor: Color = .clear
    private var userTextColor: Color = .white
    private var assistantTextColor: Color = .black
    private var userTypingColor: Color = .white.opacity(0.7)
    private var assistantTypingColor: Color = .gray.opacity(0.7)
    private var bubbleCornerRadius: CGFloat = 16
    private var bubblePadding: EdgeInsets?
    
    // Markdown theme customization
    private var markdownTheme: ((Theme) -> Theme)?
    
    private var visibleMessages: [Message] {
        // First filter out system messages
        let userAndAssistantMessages = dataSource.messages.filter { $0.role != .system }
        
        // Then apply our visible message count limit
        let startIndex = max(0, userAndAssistantMessages.count - dataSource.visibleMessageCount)
        return Array(userAndAssistantMessages[startIndex...])
    }
    
    public init(
        dataSource: DataSource,
        inputType: ChatInputType = .combined,
        style: Style = DefaultChatContainerStyle()
    ) {
        self.dataSource = dataSource
        self.inputType = inputType
        self.style = style
    }
    
    private func defaultMarkdownTheme(for message: Message) -> Theme {
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
    private func makeInputView() -> some View {
        switch inputType {
        case .text:
            makeTextOnlyInput()
        case .voice:
            makeVoiceOnlyInput()
        case .combined:
            makeCombinedInput()
        }
    }
    
    private func makeTextOnlyInput() -> some View {
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
    
    private func makeVoiceOnlyInput() -> some View {
        makeVoiceButton()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, style.horizontalPadding)
            .padding(.vertical, 8)
    }
    
    private func makeCombinedInput() -> some View {
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
    
    private func makeVoiceButton() -> some View {
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
    
    private func makeSendButton() -> some View {
        Button(action: sendCurrentInput) {
            style.sendButtonImage
                .font(.system(size: style.inputButtonSize * 0.8))
                .foregroundStyle(style.sendButtonTint)
                .frame(width: style.inputButtonSize, height: style.inputButtonSize)
        }
        .disabled(dataSource.userInputBinding.wrappedValue.isEmpty || dataSource.isStreaming)
    }
    
    private func sendCurrentInput() {
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
    fileprivate func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
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

public extension ChatContainer {
    func userBubbleStyle(
        backgroundColor: Color,
        textColor: Color,
        typingIndicatorColor: Color? = nil
    ) -> ChatContainer {
        var container = self
        container.userBubbleColor = backgroundColor
        container.userTextColor = textColor
        container.userTypingColor = typingIndicatorColor ?? textColor.opacity(0.7)
        return container
    }
    
    func assistantBubbleStyle(
        backgroundColor: Color,
        textColor: Color,
        typingIndicatorColor: Color? = nil
    ) -> ChatContainer {
        var container = self
        container.assistantBubbleColor = backgroundColor
        container.assistantTextColor = textColor
        container.assistantTypingColor = typingIndicatorColor ?? textColor.opacity(0.7)
        return container
    }
    
    func bubbleCornerRadius(_ radius: CGFloat) -> ChatContainer {
        var container = self
        container.bubbleCornerRadius = radius
        return container
    }
    
    func bubblePadding(_ padding: EdgeInsets) -> ChatContainer {
        var container = self
        container.bubblePadding = padding
        return container
    }
    
    func markdownTheme(_ transform: @escaping (Theme) -> Theme) -> ChatContainer {
        var container = self
        container.markdownTheme = transform
        return container
    }
    
    func inputFieldStyle(
        backgroundColor: Color,
        textColor: Color,
        placeholder: String,
        cornerRadius: CGFloat? = nil,
        padding: EdgeInsets? = nil
    ) -> ChatContainer {
        var container = self
        var modifiedStyle = style
        modifiedStyle.inputFieldBackgroundColor = backgroundColor
        modifiedStyle.inputFieldTextColor = textColor
        modifiedStyle.inputFieldPlaceholder = placeholder
        if let cornerRadius = cornerRadius {
            modifiedStyle.inputFieldCornerRadius = cornerRadius
        }
        if let padding = padding {
            modifiedStyle.inputFieldPadding = padding
        }
        container.style = modifiedStyle
        return container
    }
    
    func inputButtonStyle(
        size: CGFloat? = nil,
        padding: CGFloat? = nil,
        sendImage: Image? = nil,
        sendTint: Color? = nil,
        sendBackgroundColor: Color? = nil,
        voiceImage: Image? = nil,
        voiceActiveImage: Image? = nil,
        voiceTint: Color? = nil,
        voiceActiveTint: Color? = nil,
        voiceBackgroundColor: Color? = nil,
        voiceActiveBackgroundColor: Color? = nil
    ) -> ChatContainer {
        var container = self
        var modifiedStyle = style
        
        // Common properties
        if let size = size {
            modifiedStyle.inputButtonSize = size
        }
        if let padding = padding {
            modifiedStyle.inputButtonPadding = padding
        }
        
        // Send button specific
        if let sendImage = sendImage {
            modifiedStyle.sendButtonImage = sendImage
        }
        if let sendTint = sendTint {
            modifiedStyle.sendButtonTint = sendTint
        }
        if let sendBackgroundColor = sendBackgroundColor {
            modifiedStyle.sendButtonBackgroundColor = sendBackgroundColor
        }
        
        // Voice button specific
        if let voiceImage = voiceImage {
            modifiedStyle.voiceButtonImage = voiceImage
        }
        if let voiceActiveImage = voiceActiveImage {
            modifiedStyle.voiceButtonActiveImage = voiceActiveImage
        }
        if let voiceTint = voiceTint {
            modifiedStyle.voiceButtonTint = voiceTint
        }
        if let voiceActiveTint = voiceActiveTint {
            modifiedStyle.voiceButtonActiveTint = voiceActiveTint
        }
        if let voiceBackgroundColor = voiceBackgroundColor {
            modifiedStyle.voiceButtonBackgroundColor = voiceBackgroundColor
        }
        if let voiceActiveBackgroundColor = voiceActiveBackgroundColor {
            modifiedStyle.voiceButtonActiveBackgroundColor = voiceActiveBackgroundColor
        }
        
        container.style = modifiedStyle
        return container
    }
}
