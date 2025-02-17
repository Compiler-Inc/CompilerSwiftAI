import SwiftUI

@MainActor
public protocol ChatDataSource: Observable {
    var messages: [Message] { get }

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
    var isRecording: Bool { false }
    
} 
