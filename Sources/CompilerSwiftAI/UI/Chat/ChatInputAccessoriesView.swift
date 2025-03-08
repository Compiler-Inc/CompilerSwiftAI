//
//  SwiftUIView.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI

struct ChatInputFieldAccessoriesView: View {
    private let onSendTap: () -> Void
    private let onAttachPhotos: () -> Void
    private let onAttachFiles: () -> Void
    
    @State private var showAddContextMenu = false
    @State private var isLocationOn: Bool = false
    
    @Binding private var text: String
    @Binding private var isLoading: Bool
    
    private var textIsEmpty: Bool {
        text.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }
    
    internal init(
        onSendTap: @escaping () -> Void,
        onAttachPhotos: @escaping () -> Void,
        onAttachFiles: @escaping () -> Void,
        text: Binding<String>,
        isLoading: Binding<Bool>
    ) {
        self.onSendTap = onSendTap
        self.onAttachPhotos = onAttachPhotos
        self.onAttachFiles = onAttachFiles
        self._text = text
        self._isLoading = isLoading
    }
    
    var buttonBackground: Color {
        if isLoading {
            return Color(uiColor: UIColor.systemFill)
        }
        
        if textIsEmpty {
            return Color(uiColor: UIColor.secondarySystemFill)
        }
        
        return .accentColor
    }
    
    var buttonForegroundColor: Color {
        guard textIsEmpty == false || isLoading else {
            return .secondary
        }
        
        return .primary
    }
    
    var body: some View {
        HStack {
            Menu {
                AddButtonContextMenu(
                    onAttachPhotos: onAttachPhotos,
                    onAttachFiles: onAttachFiles
                )
            } label: {
                Image(systemName: "plus")
                    .font(.body)
                    .bold()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundColor(.primary)
                    .background(Color(uiColor: UIColor.systemBackground))
                    .transition(.symbolEffect(.automatic))
            }
            .shadow(radius: 4)
            .clipShape(Circle())
            .buttonBorderShape(.circle)
            .disabled(isLoading)
            
            Spacer()
            
            Button {
                onSendTap()
            } label: {
                Image(systemName: isLoading ? "stop.fill" : "arrow.up")
                    .font(.body)
                    .bold()
                    .frame(width: 16, height: 16)
                    .padding(8)
                    .foregroundColor(buttonForegroundColor)
                    .background(buttonBackground)
                    .clipShape(Circle())
                    .transition(.symbolEffect(.automatic))
            }
            .animation(.snappy, value: isLoading)
            .disabled(text.isEmpty && !isLoading)
        }
    }
}

#Preview {
    ChatInputFieldAccessoriesView(onSendTap: {}, onAttachPhotos: {}, onAttachFiles: {}, text: .constant(""), isLoading: .constant(false))
        .frame(minWidth: 325, maxWidth: .infinity, minHeight: 100)
        .background(.background)
}

#Preview {
    ChatInputFieldAccessoriesView(onSendTap: {}, onAttachPhotos: {}, onAttachFiles: {}, text: .constant(""), isLoading: .constant(true))
        .frame(minWidth: 325, maxWidth: .infinity, minHeight: 100)
        .background(.background)
}
