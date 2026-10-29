import Foundation
import MinkeyEngine

/// A key combination: a virtual key code and modifier bits.
public struct Shortcut: Codable, Equatable, Sendable {
    public var keyCode: UInt16
    public var modifiers: UInt

    public static let shift: UInt = 1 << 17
    public static let control: UInt = 1 << 18
    public static let option: UInt = 1 << 19
    public static let command: UInt = 1 << 20

    public init(keyCode: UInt16, modifiers: UInt) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

public struct Settings: Codable, Equatable, Sendable {
    public var toneStyle: ToneStyle = .new
    public var spellCheck = true
    public var toggleShortcut = Shortcut(keyCode: 49, modifiers: Shortcut.control | Shortcut.option)
    public var macros = Macros()
    public var languages = AppLanguages()
    public var overrides: [String: DeliveryMode] = [:]

    public init() {}
}

public struct SettingsStore: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// The saved settings, or defaults when there are none; an unreadable file is kept aside, never deleted.
    public func load() -> Settings {
        guard let data = try? Data(contentsOf: url) else { return Settings() }
        if let settings = try? JSONDecoder().decode(Settings.self, from: data) { return settings }
        let aside = url.appendingPathExtension("corrupt-\(Int(Date().timeIntervalSince1970))")
        try? FileManager.default.moveItem(at: url, to: aside)
        return Settings()
    }

    public func save(_ settings: Settings) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: url, options: .atomic)
    }
}
