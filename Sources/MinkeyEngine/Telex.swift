public enum ToneStyle: String, Codable, Sendable {
    /// `hoà`, `thuý`
    case new
    /// `hòa`, `thúy`
    case old
}

/// Turns Telex keystrokes into the current Vietnamese word.
public struct TelexEngine: Sendable {
    public var toneStyle: ToneStyle
    public var spellCheck: Bool

    private var letters: [Letter] = []
    /// Set by an undo: the rest of the word is typed as plain letters, so a repeated key never toggles.
    private var isLiteral = false
    /// The keys behind `letters`, for restoring a word that ends up not being Vietnamese; nil once a Delete
    /// inside a changed word makes them unknowable.
    private var keys: [Character]? = []

    public init(toneStyle: ToneStyle = .new, spellCheck: Bool = true) {
        self.toneStyle = toneStyle
        self.spellCheck = spellCheck
    }

    public var word: String { letters.map(\.rendered).joined() }

    public mutating func type(_ key: Character) {
        keys?.append(key)
        if isLiteral || !applyChecked(key) {
            letters.append(Letter(key))
            if !isLiteral { placeTone() }
        }
    }

    public mutating func deleteBackward() {
        guard !letters.isEmpty else { return }
        if let typed = keys, String(typed) == word {
            keys?.removeLast()
        } else {
            keys = nil
        }
        letters.removeLast()
        if letters.isEmpty {
            isLiteral = false
            keys = []
        }
    }

    /// Continues `word`, already on screen, as the word being typed.
    public mutating func resume(_ word: String) {
        letters = word.map(Letter.init(precomposed:))
        isLiteral = false
        keys = nil
    }

    /// Finishes the word at a boundary key: one that isn't Vietnamese goes back to the keys as typed.
    public mutating func endWord() -> String {
        var text = word
        if spellCheck, !isLiteral, let typed = keys, !Syllable.isValid(letters) { text = String(typed) }
        letters = []
        isLiteral = false
        keys = []
        return text
    }

    private mutating func applyChecked(_ key: Character) -> Bool {
        let before = (letters, isLiteral)
        guard apply(key) else { return false }
        if spellCheck, !isLiteral, !Syllable.canBecomeValid(letters) {
            (letters, isLiteral) = before
            return false
        }
        return true
    }

    private static let toneKeys: [Character: Tone] = ["s": .acute, "f": .grave, "r": .hook, "x": .tilde, "j": .dot]

    /// Applies `key` as a Telex modifier; false when it is just a letter to append.
    private mutating func apply(_ key: Character) -> Bool {
        let lower = Character(key.lowercased())
        if let tone = Self.toneKeys[lower] { return applyTone(tone, key: key) }
        switch lower {
        case "z": return clearTone()
        case "a", "e", "o": return applyHat(lower, key: key)
        case "w": return applyHorn(key: key)
        case "d": return applyStroke(key: key)
        default: return false
        }
    }

    private mutating func applyTone(_ tone: Tone, key: Character) -> Bool {
        guard tonePosition() != nil else { return false }
        if currentTone == tone {
            setTone(.none)
            undo(key)
        } else {
            setTone(tone)
        }
        return true
    }

    private mutating func clearTone() -> Bool {
        guard currentTone != .none else { return false }
        setTone(.none)
        return true
    }

    private mutating func applyHat(_ base: Character, key: Character) -> Bool {
        let nucleus = nucleus()
        if let i = nucleus.first(where: { letters[$0].base == base && letters[$0].shape == .plain }) {
            reshape(i, to: .hat)
            return true
        }
        if let i = nucleus.first(where: { letters[$0].base == base && letters[$0].shape == .hat }) {
            reshape(i, to: .plain)
            undo(key)
            return true
        }
        return false
    }

    private mutating func applyHorn(key: Character) -> Bool {
        let nucleus = nucleus()
        let bases = nucleus.map { letters[$0].base }
        if let j = bases.indices.dropLast().first(where: { bases[$0] == "u" && bases[$0 + 1] == "o" }),
            letters[nucleus[j]].shape != .horn || letters[nucleus[j + 1]].shape != .horn
        {
            reshape(nucleus[j], to: .horn)
            reshape(nucleus[j + 1], to: .horn)
            return true
        }
        if bases == ["o", "a"], letters[nucleus[1]].shape == .plain {
            reshape(nucleus[1], to: .breve)
            return true
        }
        for (base, shape) in [("u", Shape.horn), ("o", .horn), ("a", .breve)] as [(Character, Shape)] {
            if let i = nucleus.first(where: { letters[$0].base == base && letters[$0].shape == .plain }) {
                reshape(i, to: shape)
                return true
            }
        }
        let hooked = nucleus.filter { letters[$0].shape == .horn || letters[$0].shape == .breve }
        if !hooked.isEmpty {
            for i in hooked { reshape(i, to: .plain) }
            undo(key)
            return true
        }
        if nucleus.isEmpty {
            var letter = Letter(key)
            letter.base = "u"
            letter.shape = .horn
            letters.append(letter)
            return true
        }
        return false
    }

    private mutating func applyStroke(key: Character) -> Bool {
        guard let first = letters.first else { return false }
        switch first.base {
        case "d":
            letters[0].base = "đ"
        case "đ":
            letters[0].base = "d"
            undo(key)
        default:
            return false
        }
        return true
    }

    private mutating func undo(_ key: Character) {
        letters.append(Letter(key))
        isLiteral = true
    }

    private mutating func reshape(_ index: Int, to shape: Shape) {
        letters[index].shape = shape
        placeTone()
    }

    private var currentTone: Tone {
        letters.first(where: { $0.tone != .none })?.tone ?? .none
    }

    private mutating func setTone(_ tone: Tone) {
        for i in letters.indices { letters[i].tone = .none }
        if tone != .none, let position = tonePosition() { letters[position].tone = tone }
    }

    /// Moves the word's tone to where it belongs after the word changed shape or grew.
    private mutating func placeTone() {
        setTone(currentTone)
    }

    /// Indices of the vowel nucleus; the `u` of `qu` and the `i` of `gi` belong to the onset.
    private func nucleus() -> [Int] {
        guard let start = letters.firstIndex(where: \.isVowel) else { return [] }
        var indices = Array(letters[start...].prefix(while: \.isVowel).indices)
        if start == 1, indices.count > 1 {
            let onset = (letters[0].base, letters[1].base)
            if onset == ("q", "u") || onset == ("g", "i") { indices.removeFirst() }
        }
        return indices
    }

    private func tonePosition() -> Int? {
        let nucleus = nucleus()
        guard let last = nucleus.last else { return nil }
        if let shaped = nucleus.last(where: { letters[$0].shape != .plain }) { return shaped }
        if nucleus.count == 1 { return last }
        if last + 1 < letters.count { return last }
        if nucleus.count == 3 { return nucleus[1] }
        let pair = String([letters[nucleus[0]].base, letters[nucleus[1]].base])
        if toneStyle == .new, ["oa", "oe", "uy"].contains(pair) { return nucleus[1] }
        return nucleus[0]
    }
}
