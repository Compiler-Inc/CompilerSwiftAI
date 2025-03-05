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
    
    @ObservedObject private var new_viewModel: NEW_ChatViewModel = .init()
    let viewModel: ChatViewModel
    var style: ChatViewStyle = .init()
    let inputType: ChatInputType
    
    @State var showScrollButton = false
    @State var scrollViewProxy: ScrollViewProxy?
    @State var isRecording = false
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
    
    // Markdown theme customization
    var markdownTheme: ((Theme) -> Theme)?
    
    public init(client: CompilerClient, inputType: ChatInputType = .combined) {
        viewModel = ChatViewModel(client: client)
        self.inputType = inputType
    }
    
    // MARK: - Input Views
    
    func sendCurrentInput() {
        print("sendingCurrentInput")
        guard !viewModel.userInputBinding.wrappedValue.isEmpty else { return }
        let input = viewModel.userInputBinding.wrappedValue
        viewModel.userInputBinding.wrappedValue = ""
        viewModel.sendMessage(input)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
//            ZStack(alignment: .bottomTrailing) {
//                ScrollViewReader { proxy in
//                    ScrollView {
//                        VStack(spacing: 12) {
//                            ForEach(items) { item in
//                                switch item {
//                                case let .message(message):
//                                    ChatBubble(message: message, style: .init())
//                                case .loadingIndicator:
//                                    TypingIndicator(style: .init())
//                                }
//                            }
//                        }
//                        .padding(.horizontal, style.horizontalPadding)
//                    }
//                    .scrollIndicators(.hidden)
//                    .onAppear {
//                        scrollViewProxy = proxy
//                    }
//                }
//                
//                if showScrollButton {
//                    ScrollDownButton(
//                        onTap: {
//                            withAnimation(.spring(duration: 0.3)) {
//                                scrollViewProxy?.scrollTo("bottom", anchor: .bottom)
//                            }
//                            showScrollButton = false
//                        },
//                        style: style
//                    )
//                }
//            }
            
            ChatInputView(
                onAttachPhotos: {
                },
                onAttachFiles: {
                },
                onSendTap: {
                    _ in
                },
                dismissKeyboard: dismissKeyboard.eraseToAnyPublisher(),
                isLoading: $new_viewModel.isLoading
            )
            .padding(.horizontal, 16)
            .safeAreaPadding(.bottom, 8)
        }
    }
}

#Preview {
    ChatView(client: .init(appID: UUID(uuidString: "asdsad")!), inputType: .text)
}
