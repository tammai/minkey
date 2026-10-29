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

    public init(importing data: Data) throws {
        self = try JSONDecoder().decode(Macros.self, from: data)
    }
}
