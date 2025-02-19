import SwiftUI
import MarkdownUI

struct ChatViewStyle {
    var scrollButtonImage: Image = Image(systemName: "arrow.down.circle.fill")
    var scrollButtonTint: Color = .white
    var scrollButtonBackgroundColor: Color = .blue
    var scrollButtonShadowRadius: CGFloat = 4
    var horizontalPadding: CGFloat = 16
    
    // Input field styling
    var inputFieldBackgroundColor: Color = .gray.opacity(0.1)
    var inputFieldTextColor: Color = .primary
    var inputFieldPlaceholder: String = "Message"
    var inputFieldCornerRadius: CGFloat = 20
    var inputFieldPadding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 40)
    
    // Common button styling
    var inputButtonSize: CGFloat = 28
    var inputButtonPadding: CGFloat = 0
    
    // Send button specific
    var sendButtonImage: Image = Image(systemName: "arrow.up.circle.fill")
    var sendButtonTint: Color = .blue
    var sendButtonBackgroundColor: Color = .clear
    
    // Voice button specific
    var voiceButtonImage: Image = Image(systemName: "mic.circle.fill")
    var voiceButtonActiveImage: Image = Image(systemName: "mic.circle.fill")
    var voiceButtonTint: Color = .blue
    var voiceButtonActiveTint: Color = .red
    var voiceButtonBackgroundColor: Color = .clear
    var voiceButtonActiveBackgroundColor: Color = .clear
}
