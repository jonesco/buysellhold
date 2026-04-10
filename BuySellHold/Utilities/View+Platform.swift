import SwiftUI

extension View {
    /// Applies decimal pad keyboard on iOS; no-op on macOS (keyboardType is iOS-only).
    @ViewBuilder
    func decimalPadKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    /// Applies numbers-and-punctuation keyboard on iOS; no-op on macOS.
    @ViewBuilder
    func numbersAndPunctuationKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }
}
