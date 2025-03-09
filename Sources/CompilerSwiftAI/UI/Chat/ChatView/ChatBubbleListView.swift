//
//  SwiftUIView.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/7/25.
//

import SwiftUI

struct ChatBubbleListView: View {
    enum Item: Identifiable {
        case message(message: Message)
        case functionCall(description: String, id: String)
        case loadingIndicator
        
        var id: String {
            switch self {
            case let .message(message):
                return message.id
            case let .functionCall(_, id):
                return id
            case .loadingIndicator:
                return "loading-indicator"
            }
        }
    }
    
    @State private var items: [Item] = []
    
    private var style: ChatViewStyle = .init()
    
    init(style: ChatViewStyle) {
        self.style = style
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    ForEach(items) { item in
                        switch item {
                        case let .message(message):
                            ChatBubble(message: message, style: .init())
                        case let .functionCall(description, id):
                            Text(description)
                        case .loadingIndicator:
                            TypingIndicator(style: .init())
                        }
                    }
                }
                .padding(.horizontal, style.horizontalPadding)
            }
            .scrollIndicators(.hidden)
        }
    }
}

#Preview {
    ChatBubbleListView(style: .init())
}
