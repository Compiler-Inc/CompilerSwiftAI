import SwiftUI
import Observation
import MarkdownUI

// MARK: - Input Types

public enum ChatInputType {
    case text
    case voice
    case combined
}

// MARK: - Chat Container Style

public protocol ChatViewStyle {
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

public struct DefaultChatViewStyle: ChatViewStyle {
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
