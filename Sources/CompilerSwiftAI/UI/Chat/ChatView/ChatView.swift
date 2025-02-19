import SwiftUI
import MarkdownUI

public enum ChatInputType {
    case text
    case voice
    case combined
}

@MainActor
public struct ChatView: View {
    let viewModel: ChatViewModel
    var style: ChatViewStyle = ChatViewStyle()
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
        let userAndAssistantMessages = viewModel.messages.filter { $0.role != .system }
        
        // Then apply our visible message count limit
        let startIndex = max(0, userAndAssistantMessages.count - viewModel.visibleMessageCount)
        return Array(userAndAssistantMessages[startIndex...])
    }
    
    public init(client: CompilerClient, inputType: ChatInputType = .combined) {
        self.viewModel = ChatViewModel(client: client)
        self.inputType = inputType
    }

    // MARK: - Input Views
    func sendCurrentInput() {
        guard !viewModel.userInputBinding.wrappedValue.isEmpty else { return }
        let input = viewModel.userInputBinding.wrappedValue
        viewModel.userInputBinding.wrappedValue = ""
        viewModel.sendMessage(input)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
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
