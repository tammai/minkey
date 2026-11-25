import Foundation
import MinkeyEngine

public struct Settings: Codable, Equatable, Sendable {
    public var toneStyle: ToneStyle = .new
    public var spellCheck = true
    public var macros = Macros()
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
