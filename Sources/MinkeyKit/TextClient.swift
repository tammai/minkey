import Foundation

/// The text field minkey types into; the app wraps InputMethodKit's client in this.
public protocol TextClient: AnyObject {
    var bundleID: String { get }
    func selectedRange() -> NSRange
    /// The text in `range` (UTF-16), or nil when the app can't report it.
    func text(in range: NSRange) -> String?
    /// Replaces `range` with `text`; `NSNotFound` inserts at the cursor, replacing any marked text.
    func insert(_ text: String, replacing range: NSRange)
    /// Shows `text` as marked (composing) text in place of any marked text.
    func setMarked(_ text: String)
}
