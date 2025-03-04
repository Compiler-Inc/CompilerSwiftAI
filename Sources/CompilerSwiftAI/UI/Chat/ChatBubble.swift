import MarkdownUI
import SwiftUI

// Default implementation
struct ChatBubbleStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var padding: EdgeInsets
    var cornerRadius: CGFloat

    // Typing indicator styling
    var typingIndicatorColor: Color
    var typingIndicatorSize: CGFloat
    var typingIndicatorSpacing: CGFloat

    init(
        backgroundColor: Color = .blue,
        foregroundColor: Color = .white,
        padding: EdgeInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16),
        cornerRadius: CGFloat = 16,
        typingIndicatorColor: Color = .gray.opacity(0.5),
        typingIndicatorSize: CGFloat = 6,
        typingIndicatorSpacing: CGFloat = 4
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.typingIndicatorColor = typingIndicatorColor
        self.typingIndicatorSize = typingIndicatorSize
        self.typingIndicatorSpacing = typingIndicatorSpacing
    }

    func makeBubbleShape() -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }
}

// MARK: - Chat Bubble View

struct ChatBubble: View {
    let message: Message
    var style: ChatBubbleStyle
    @State private var isAnimating = false

    var content: String {
        switch message.state {
        case let .streaming(partial):
            return partial
        case .complete:
            return message.content
        }
    }

    var markdownTheme: Theme {
        Theme()
            .text {
                ForegroundColor(style.foregroundColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                BackgroundColor(.black.opacity(0.1))
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
                        ForegroundColor(style.foregroundColor)
                    }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.8), bottom: .em(0.4))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.3))
                        ForegroundColor(style.foregroundColor)
                    }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.6), bottom: .em(0.3))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.1))
                        ForegroundColor(style.foregroundColor)
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
            .bulletedListMarker { _ in
                Text("•")
                    .foregroundColor(style.foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .numberedListMarker { configuration in
                Text("\(configuration.itemNumber).")
                    .foregroundColor(style.foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
    }

    public init(message: Message, style: ChatBubbleStyle = ChatBubbleStyle()) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading) {
            Markdown(content)
                .textSelection(.enabled)
                .markdownTheme(markdownTheme)
                .padding(style.padding)
                .background(
                    style.makeBubbleShape()
                        .fill(style.backgroundColor)
                )
                .onChange(of: message.state) { _, newState in
                    isAnimating = newState.isStreaming
                }
                .onAppear {
                    isAnimating = message.state.isStreaming
                }

            if message.state.isStreaming {
                TypingIndicator(style: style)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let style: ChatBubbleStyle
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: style.typingIndicatorSpacing) {
            ForEach(0 ..< 3) { index in
                Circle()
                    .fill(style.typingIndicatorColor)
                    .frame(width: style.typingIndicatorSize, height: style.typingIndicatorSize)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .padding(.leading, 8)
        .onAppear { isAnimating = true }
    }
}

// MARK: - View Modifiers

extension ChatBubble {
    public func bubbleBackground<S: Shape>(_: S, color: Color) -> ChatBubble {
        var modifiedStyle = style
        modifiedStyle.backgroundColor = color
        return ChatBubble(message: message, style: modifiedStyle)
    }

    public func bubbleForegroundColor(_ color: Color) -> ChatBubble {
        var modifiedStyle = style
        modifiedStyle.foregroundColor = color
        return ChatBubble(message: message, style: modifiedStyle)
    }

    public func bubblePadding(_ padding: EdgeInsets) -> ChatBubble {
        var modifiedStyle = style
        modifiedStyle.padding = padding
        return ChatBubble(message: message, style: modifiedStyle)
    }

    public func bubbleCornerRadius(_ radius: CGFloat) -> ChatBubble {
        var modifiedStyle = style
        modifiedStyle.cornerRadius = radius
        return ChatBubble(message: message, style: modifiedStyle)
    }

    public func typingIndicator(color: Color, size: CGFloat = 6, spacing: CGFloat = 4) -> ChatBubble {
        var modifiedStyle = style
        modifiedStyle.typingIndicatorColor = color
        modifiedStyle.typingIndicatorSize = size
        modifiedStyle.typingIndicatorSpacing = spacing
        return ChatBubble(message: message, style: modifiedStyle)
    }
}
