import AppKit
import InputMethodKit
import MinkeyKit

/// InputMethodKit's client seen through minkey's `TextClient`.
final class IMKTextClient: TextClient {
    private let client: any IMKTextInput

    init(_ client: any IMKTextInput) {
        self.client = client
    }

    var bundleID: String { client.bundleIdentifier() ?? "" }

    func selectedRange() -> NSRange { client.selectedRange() }

    func text(in range: NSRange) -> String? {
        client.attributedSubstring(from: range)?.string
    }

    func insert(_ text: String, replacing range: NSRange) {
        client.insertText(text, replacementRange: range)
    }

    func setMarked(_ text: String) {
        client.setMarkedText(
            NSAttributedString(string: text),
            selectionRange: NSRange(location: text.utf16.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
    }
}
