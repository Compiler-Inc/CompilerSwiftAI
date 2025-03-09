//
//  AddButtonContextMenu.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI

struct AddButtonContextMenu: View {
    private let onAttachPhotos: () -> Void
    private let onAttachFiles: () -> Void
    
    init(
        onAttachPhotos: @escaping () -> Void,
        onAttachFiles: @escaping () -> Void
    ) {
        self.onAttachPhotos = onAttachPhotos
        self.onAttachFiles = onAttachFiles
    }
    
    var body: some View {
        Button {
            onAttachPhotos()
        } label: {
            Label("Attach Photos", systemImage: "photo")
        }
        
        Button {
            onAttachFiles()
        } label: {
            Label("Attach Files", systemImage: "folder")
        }
    }
}

#Preview {
    AddButtonContextMenu(onAttachPhotos: {}, onAttachFiles: {})
}
