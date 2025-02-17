import SwiftUI

extension View {
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
}
