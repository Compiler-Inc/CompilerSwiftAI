import MarkdownUI
import SwiftUI

extension ChatView {
    func defaultMarkdownTheme(for message: Message) -> Theme {
        let foregroundColor = message.role == .user ? userTextColor : assistantTextColor
        
        return Theme()
            .text {
                ForegroundColor(foregroundColor)
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(.em(0.85))
                ForegroundColor(foregroundColor)
            }
            .codeBlock { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamilyVariant(.monospaced)
                            FontSize(.em(0.85))
                            ForegroundColor(foregroundColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(foregroundColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
            }
            .strong {
                FontWeight(.bold)
            }
            .emphasis {
                FontStyle(.italic)
            }
            .heading1 { configuration in
                configuration.label
                    .markdownMargin(top: .em(1), bottom: .em(0.5))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.5))
                        ForegroundColor(foregroundColor)
                    }
            }
            .heading2 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.8), bottom: .em(0.4))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.3))
                        ForegroundColor(foregroundColor)
                    }
            }
            .heading3 { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.6), bottom: .em(0.3))
                    .markdownTextStyle {
                        FontWeight(.bold)
                        FontSize(.em(1.1))
                        ForegroundColor(foregroundColor)
                    }
            }
            .list { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.5))
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: .em(0.25))
            }
            .bulletedListMarker { configuration in
                Text("•")
                    .foregroundColor(foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
            .numberedListMarker { configuration in
                Text("\(configuration.itemNumber).")
                    .foregroundColor(foregroundColor)
                    .relativeFrame(minWidth: .em(1.5), alignment: .trailing)
            }
    }
}
