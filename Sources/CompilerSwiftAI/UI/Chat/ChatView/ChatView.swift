import MarkdownUI
import SwiftUI
import Combine

public enum ChatInputType {
    case text
    case voice
    case combined
}

@MainActor
public struct ChatView: View {
    enum Item: Identifiable {
        case message(message: Message)
        case loadingIndicator
        
        var id: String {
            switch self {
            case let .message(message):
                return message.id
            case .loadingIndicator:
                return "loading-indicator"
            }
        }
    }
    
    
    var style: ChatViewStyle = .init()
    let inputType: ChatInputType
    
    @ObservedObject var viewModel: ChatViewModel
    @State var showScrollButton = false
    @State var scrollViewProxy: ScrollViewProxy?
    @State var loading = false
    @State var userInput: String = ""
    @State private var items: [Item] = []
    
    private let dismissKeyboard = PassthroughSubject<Void, Never>()
    
    // Bubble styling properties
    var userBubbleColor: Color = .blue
    var assistantBubbleColor: Color = .clear
    var userTextColor: Color = .white
    var assistantTextColor: Color = .black
    var userTypingColor: Color = .white.opacity(0.7)
    var assistantTypingColor: Color = .gray.opacity(0.7)
    var bubbleCornerRadius: CGFloat = 16
    var bubblePadding: EdgeInsets?
    var markdownTheme: ((Theme) -> Theme)?
    
    public init(client: CompilerClient, inputType: ChatInputType = .combined) {
        viewModel = ChatViewModel(client: client)
        self.inputType = inputType
    }
    
    // MARK: - Input Views
    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                
                
                if showScrollButton {
                    ScrollDownButton(
                        onTap: {
                            withAnimation(.spring(duration: 0.3)) {
                                scrollViewProxy?.scrollTo("bottom", anchor: .bottom)
                            }
                            showScrollButton = false
                        },
                        style: style
                    )
                }
            }
            
            ChatInputView(
                onAttachPhotos: {
                },
                onAttachFiles: {
                },
                onSendTap: {
                    _ in
                },
                dismissKeyboard: dismissKeyboard.eraseToAnyPublisher(),
                isLoading: $loading
            )
            .padding(.horizontal, 16)
            .safeAreaPadding(.bottom, 8)
        }
    }
}

#Preview {
    ChatView(client: .init(appID: "asdsad"), inputType: .text)
}
