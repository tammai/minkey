import Foundation
import MinkeyEngine

public enum DeliveryMode: Sendable {
    case direct, marked
}

public enum Key: Sendable {
    case letter(Character)
    case delete
    /// A key that ends the word: space or punctuation (its character), or Return, Tab, arrows and chords (nil).
    case boundary(Character?)
}

/// Turns keys into edits on a text client: finished text replaced in place (direct), or composing text (marked)
/// for apps that can't report what is before the cursor.
public final class Delivery {
    public var engine: TelexEngine
    public var overrides: [String: DeliveryMode]

    public private(set) var mode: DeliveryMode = .direct

    /// Longer runs of letters (a held key, a pasted burst) aren't words; they pass through untouched.
    static let maxWordLength = 32

    private var isTracking = false
    private var wordStart = 0
    private var shown = ""
    /// Cursor positions minkey's own edits can explain: now, and one edit back for apps whose reports lag.
    private var expectedCursors: [Int] = []
    private var detectedModes: [String: DeliveryMode] = [:]

    public init(engine: TelexEngine = TelexEngine(), overrides: [String: DeliveryMode] = [:]) {
        self.engine = engine
        self.overrides = overrides
    }

    public func activate(_ client: TextClient) {
        drop()
        mode = overrides[client.bundleID] ?? detectedModes[client.bundleID] ?? detectMode(client)
        detectedModes[client.bundleID] = mode
    }

    public func deactivate(_ client: TextClient) {
        if mode == .marked, isTracking { client.insert(engine.endWord(), replacing: Self.atCursor) }
        drop()
    }

    /// True when minkey handled the key; false lets the app handle it as usual.
    public func handle(_ key: Key, client: TextClient) -> Bool {
        mode == .marked ? handleMarked(key, client: client) : handleDirect(key, client: client)
    }

    // MARK: Direct

    private func handleDirect(_ key: Key, client: TextClient) -> Bool {
        switch key {
        case .letter(let letter):
            if isTracking, !cursorIsExpected(client) { drop() }
            if !isTracking {
                guard startWord(client) else { return false }
                if mode == .marked { return handleMarked(key, client: client) }
            }
            engine.type(letter)
            guard engine.word.count <= Self.maxWordLength else {
                drop()
                return false
            }
            show(engine.word, client: client)
            return true
        case .delete:
            guard isTracking, !shown.isEmpty, cursorIsExpected(client) else {
                drop()
                return false
            }
            engine.deleteBackward()
            show(engine.word, client: client)
            if shown.isEmpty { drop() }
            return true
        case .boundary(let character):
            guard isTracking, cursorIsExpected(client) else {
                drop()
                return false
            }
            let final = engine.endWord()
            guard let character else {
                show(final, client: client)
                drop()
                return false
            }
            show(final + String(character), client: client)
            drop()
            return true
        }
    }

    /// Begins tracking at the cursor, continuing the word before it when two reads agree on it.
    private func startWord(_ client: TextClient) -> Bool {
        let cursor = client.selectedRange()
        guard cursor.location != NSNotFound, cursor.length == 0 else { return false }
        if cursor.location > 0 {
            guard let before = client.text(in: NSRange(location: cursor.location - 1, length: 1)) else {
                mode = .marked
                detectedModes[client.bundleID] = .marked
                return true
            }
            if before.first?.isLetter == true {
                guard let word = wordBefore(cursor.location, client: client) else { return false }
                engine.resume(word)
                begin(at: cursor.location - word.utf16.count, shown: word)
                return true
            }
        }
        _ = engine.endWord()
        begin(at: cursor.location, shown: "")
        return true
    }

    private func wordBefore(_ location: Int, client: TextClient) -> String? {
        let start = max(0, location - Self.maxWordLength)
        let range = NSRange(location: start, length: location - start)
        guard let first = client.text(in: range), let second = client.text(in: range), first == second else {
            return nil
        }
        let word = String(first.reversed().prefix(while: \.isLetter).reversed())
        return word.isEmpty || word.count >= Self.maxWordLength ? nil : word
    }

    private func begin(at start: Int, shown text: String) {
        isTracking = true
        wordStart = start
        shown = text
        expectedCursors = [start + text.utf16.count]
    }

    private func cursorIsExpected(_ client: TextClient) -> Bool {
        let cursor = client.selectedRange()
        return cursor.length == 0 && expectedCursors.contains(cursor.location)
    }

    /// Replaces only the characters of the word that changed.
    private func show(_ text: String, client: TextClient) {
        let old = Array(shown)
        let new = Array(text)
        let same = zip(old, new).prefix(while: { $0 == $1 }).count
        let keptUnits = String(old[..<same]).utf16.count
        let range = NSRange(location: wordStart + keptUnits, length: shown.utf16.count - keptUnits)
        let replacement = String(new[same...])
        if range.length > 0 || !replacement.isEmpty { client.insert(replacement, replacing: range) }
        shown = text
        let cursor = wordStart + text.utf16.count
        expectedCursors = [cursor, expectedCursors.first].compactMap { $0 }
    }

    private func drop() {
        isTracking = false
        shown = ""
        expectedCursors = []
        _ = engine.endWord()
    }

    // MARK: Marked

    private static let atCursor = NSRange(location: NSNotFound, length: 0)

    private func handleMarked(_ key: Key, client: TextClient) -> Bool {
        switch key {
        case .letter(let letter):
            engine.type(letter)
            isTracking = true
            client.setMarked(engine.word)
            return true
        case .delete:
            guard isTracking else { return false }
            engine.deleteBackward()
            client.setMarked(engine.word)
            if engine.word.isEmpty { drop() }
            return true
        case .boundary(let character):
            guard isTracking else { return false }
            client.insert(engine.endWord() + (character.map(String.init) ?? ""), replacing: Self.atCursor)
            drop()
            return character != nil
        }
    }

    private func detectMode(_ client: TextClient) -> DeliveryMode {
        let cursor = client.selectedRange()
        guard cursor.location != NSNotFound else { return .marked }
        guard cursor.location > 0 else { return .direct }
        return client.text(in: NSRange(location: cursor.location - 1, length: 1)) == nil ? .marked : .direct
    }
}
