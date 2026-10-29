import Foundation

/// User shorthand, expanded at the end of a word with the case the user typed.
public struct Macros: Codable, Equatable, Sendable {
    public var entries: [String: String]
    public var inEnglishMode: Bool

    public init(entries: [String: String] = [:], inEnglishMode: Bool = false) {
        self.entries = entries
        self.inEnglishMode = inEnglishMode
    }

    /// `btw` → `by the way`, `Btw` → `By the way`, `BTW` → `BY THE WAY`.
    public func expand(_ word: String) -> String? {
        guard let expansion = entries[word.lowercased()] else { return nil }
        if word.count > 1, word == word.uppercased() { return expansion.uppercased() }
        if word.first?.isUppercase == true { return expansion.prefix(1).uppercased() + expansion.dropFirst() }
        return expansion
    }

    public func exported() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// Reads an exported file; shorthand is matched case-insensitively, so keys are folded to lowercase.
    public init(importing data: Data) throws {
        let decoded = try JSONDecoder().decode(Macros.self, from: data)
        let folded = decoded.entries.map { ($0.key.lowercased(), $0.value) }
        self.init(
            entries: Dictionary(folded, uniquingKeysWith: { _, last in last }), inEnglishMode: decoded.inEnglishMode)
    }
}
