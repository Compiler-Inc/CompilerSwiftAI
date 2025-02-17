import SwiftUI

@MainActor
public protocol ChatDataSource: Observable {
    var messages: [Message] { get }
    var visibleMessageCount: Int { get }
    var shouldShowScrollButton: Bool { get }
    var spacing: CGFloat { get }
    
    // Text input handling
    var userInputBinding: Binding<String> { get }
    var isStreaming: Bool { get }
    
    // Voice input handling
    var isRecording: Bool { get }
    func toggleRecording()
    
    // Message handling
    func sendMessage(_ text: String)
}

// Default implementations
@MainActor
public extension ChatDataSource {
    var visibleMessageCount: Int { 15 }
    var shouldShowScrollButton: Bool { true }
    var spacing: CGFloat { 12 }
    var isRecording: Bool { false }
    
} 
