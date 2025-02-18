import MarkdownUI
import SwiftUI

public extension ChatView {
    func userBubbleStyle(
        backgroundColor: Color,
        textColor: Color,
        typingIndicatorColor: Color? = nil
    ) -> ChatView {
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
    ) -> ChatView {
        var container = self
        container.assistantBubbleColor = backgroundColor
        container.assistantTextColor = textColor
        container.assistantTypingColor = typingIndicatorColor ?? textColor.opacity(0.7)
        return container
    }
    
    func bubbleCornerRadius(_ radius: CGFloat) -> ChatView {
        var container = self
        container.bubbleCornerRadius = radius
        return container
    }
    
    func bubblePadding(_ padding: EdgeInsets) -> ChatView {
        var container = self
        container.bubblePadding = padding
        return container
    }
    
    func markdownTheme(_ transform: @escaping (Theme) -> Theme) -> ChatView {
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
    ) -> ChatView {
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
    ) -> ChatView {
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
