import SwiftUI

extension Color {
    static let dlm = DLMColors.self
}

enum DLMColors {
    // Primary Colors
    static let primary = Color(hex: 0x2F4DDE)
    static let primary10 = Color(hex: 0x050816)
    static let primary20 = Color(hex: 0x0E1743)
    static let primary75 = Color(hex: 0x8D9DED)
    static let primary100 = Color(hex: 0xEAEDFC)

    // Secondary Colors
    static let secondary = Color(hex: 0xDE5A2F)
    static let secondary10 = Color(hex: 0x160905)
    static let secondary20 = Color(hex: 0x431B0E)
    static let secondary75 = Color(hex: 0xEFAD97)
    static let secondary100 = Color(hex: 0xFCEFEA)

    // Gradients
    static let dlmGradient = LinearGradient(
        colors: [Color(hex: 0x8D9DED), Color(hex: 0xEFAD97)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// Helper extension to create colors from hex values
private extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
