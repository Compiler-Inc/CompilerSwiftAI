import MarkdownUI
import SwiftUI

// MARK: - Chat Bubble View

struct ChatBubble: View {
    let message: Message
    var style: ChatBubbleStyle
    
    init(message: Message, style: ChatBubbleStyle) {
        self.message = message
        self.style = style
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

    var body: some View {
        VStack(alignment: message.role == .user ? .trailing : .leading) {
            Markdown(message.content)
                .textSelection(.enabled)
                .markdownTheme(markdownTheme)
                .padding(style.padding)
                .background(
                    style.makeBubbleShape()
                        .fill(style.backgroundColor)
                )
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
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
