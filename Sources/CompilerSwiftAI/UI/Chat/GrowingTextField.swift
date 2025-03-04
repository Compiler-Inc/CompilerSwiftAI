import SwiftUI
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

// Platform abstraction
extension View {
    var screenWidth: CGFloat {
        #if os(iOS)
            UIScreen.main.bounds.width
        #else
            NSScreen.main?.visibleFrame.width ?? 800
        #endif
    }
}

extension NSAttributedString.Key {
    static var platformDefaultFont: Any {
        #if os(iOS)
            UIFont.preferredFont(forTextStyle: .body)
        #else
            NSFont.systemFont(ofSize: NSFont.systemFontSize)
        #endif
    }
}

struct GrowingTextField: View {
    let placeholder: String
    @Binding var text: String
    let textColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    let onSubmit: () -> Void
    let trailingContent: () -> AnyView
    let style: ChatViewStyle

    init(
        placeholder: String,
        text: Binding<String>,
        textColor: Color,
        backgroundColor: Color,
        cornerRadius: CGFloat,
        padding: EdgeInsets,
        onSubmit: @escaping () -> Void,
        style: ChatViewStyle,
        @ViewBuilder trailingContent: @escaping () -> some View
    ) {
        self.placeholder = placeholder
        _text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onSubmit = onSubmit
        self.style = style
        self.trailingContent = { AnyView(trailingContent()) }
    }

    @State private var textViewHeight: CGFloat = 36 // Initial height
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HStack(spacing: 0) {
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(height: max(36, textViewHeight))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .foregroundColor(textColor)
                    .onChange(of: text) { _, newValue in
                        guard !newValue.isEmpty else {
                            textViewHeight = 36
                            return
                        }

                        let width = max(100, screenWidth - 100) // Ensure minimum width
                        let size = (newValue as NSString).boundingRect(
                            with: CGSize(width: width, height: .infinity),
                            options: [.usesFontLeading, .usesLineFragmentOrigin],
                            attributes: [.font: NSAttributedString.Key.platformDefaultFont],
                            context: nil
                        )

                        let newHeight = size.height + 20
                        textViewHeight = min(120, max(36, newHeight.isNaN ? 36 : newHeight))
                    }
                    .overlay(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.gray)
                                .allowsHitTesting(false)
                                .padding(.leading, 4)
                        }
                    }
            }
            .padding(.trailing, style.inputButtonSize + 8) // Increased spacing for larger button

            trailingContent()
                .padding(.trailing, 4) // Small edge padding
                .padding(.bottom, 4) // Add bottom padding to center vertically
        }
        .padding(EdgeInsets(
            top: padding.top,
            leading: padding.leading,
            bottom: padding.bottom,
            trailing: max(padding.trailing - style.inputButtonSize, 8) // Ensure minimum trailing space
        ))
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .onSubmit(onSubmit)
    }
}
