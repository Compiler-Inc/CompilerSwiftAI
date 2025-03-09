//
//  File.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI

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

#Preview {
    TypingIndicator(style: .init())
}
