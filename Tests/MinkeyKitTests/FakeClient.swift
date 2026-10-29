import Foundation

@testable import MinkeyKit

/// A text field. `lagsReads` reports text one edit late, like Teams; `isTerminal` behaves like the spike's terminal.
final class FakeClient: TextClient {
    let bundleID: String
    var lagsReads = false
    var isTerminal = false
    var unstableReads = false

    private(set) var value: NSMutableString
    var cursor: Int
    private(set) var markedRange: NSRange?
    private var previousValue: String
    private(set) var edits: [(range: NSRange, text: String)] = []
    private var readCount = 0

    init(_ text: String = "", bundleID: String = "com.example.app") {
        self.bundleID = bundleID
        value = NSMutableString(string: text)
        previousValue = text
        cursor = (text as NSString).length
    }

    var text: String { value as String }

    func selectedRange() -> NSRange {
        isTerminal ? NSRange(location: 1, length: 0) : NSRange(location: cursor, length: 0)
    }

    func text(in range: NSRange) -> String? {
        if isTerminal { return nil }
        readCount += 1
        let source = (lagsReads ? previousValue : text) as NSString
        guard range.location >= 0, range.location + range.length <= source.length else { return nil }
        let result = source.substring(with: range)
        return unstableReads && readCount % 2 == 0 ? result + "?" : result
    }

    func insert(_ text: String, replacing range: NSRange) {
        previousValue = self.text
        var target = range
        if range.location == NSNotFound || isTerminal {
            target = markedRange ?? NSRange(location: cursor, length: 0)
        }
        edits.append((target, text))
        value.replaceCharacters(in: target, with: text)
        cursor = target.location + (text as NSString).length
        markedRange = nil
    }

    func setMarked(_ text: String) {
        previousValue = self.text
        let target = markedRange ?? NSRange(location: cursor, length: 0)
        value.replaceCharacters(in: target, with: text)
        markedRange = text.isEmpty ? nil : NSRange(location: target.location, length: (text as NSString).length)
        cursor = target.location + (text as NSString).length
    }

    /// The app itself handling a key minkey passed through.
    func appTypes(_ key: Key) {
        previousValue = text
        switch key {
        case .letter(let c):
            value.insert(String(c), at: cursor)
            cursor += 1
        case .boundary(let c?):
            value.insert(String(c), at: cursor)
            cursor += 1
        case .delete:
            guard cursor > 0 else { return }
            let range = (text as NSString).rangeOfComposedCharacterSequence(at: cursor - 1)
            value.deleteCharacters(in: range)
            cursor = range.location
        case .boundary(nil):
            break
        }
    }
}

/// Sends each key to `delivery`, and to the app when minkey passes it through.
func send(_ keys: [Key], to delivery: Delivery, client: FakeClient) -> [Bool] {
    keys.map { key in
        let handled = delivery.handle(key, client: client)
        if !handled { client.appTypes(key) }
        return handled
    }
}

func letters(_ text: String) -> [Key] { text.map { $0 == " " ? .boundary(" ") : .letter($0) } }
