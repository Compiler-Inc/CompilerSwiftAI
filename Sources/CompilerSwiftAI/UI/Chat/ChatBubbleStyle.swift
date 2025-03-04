//
//  ChatBubbleStyle.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

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
