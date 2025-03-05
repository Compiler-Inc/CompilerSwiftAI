//
//  SwiftUIView.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI

struct ScrollDownButton: View {
    let onTap: () -> Void
    let style: ChatViewStyle
    
    var body: some View {
        Button {
            onTap()
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

#Preview {
    ScrollDownButton(onTap: {}, style: .init())
}
