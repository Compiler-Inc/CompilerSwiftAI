//
//  NEW_ChatViewModel.swift
//  CompilerSwiftAI
//
//  Created by Atharva Vaidya on 3/4/25.
//

import SwiftUI
import Combine

class NEW_ChatViewModel: ObservableObject {
    /// Indicates that we are waiting for the first token
    @Published var isLoading: Bool = false
}
