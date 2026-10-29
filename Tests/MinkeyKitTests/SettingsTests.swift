import Foundation
import Testing

@testable import MinkeyKit

private func temporaryFile() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("minkey-\(UUID().uuidString)/settings.json")
}

@Test func settingsPersistAndMacrosRoundTrip() throws {
    let url = temporaryFile()
    let store = SettingsStore(url: url)
    #expect(store.load() == Settings())

    var settings = Settings()
    settings.toneStyle = .old
    settings.spellCheck = false
    settings.toggleShortcut = Shortcut(keyCode: 6, modifiers: Shortcut.control | Shortcut.shift)
    settings.macros = Macros(entries: ["btw": "by the way"], inEnglishMode: true)
    settings.languages.chosen["com.apple.Notes"] = .english
    settings.overrides["com.microsoft.teams2"] = .marked
    try store.save(settings)
    #expect(SettingsStore(url: url).load() == settings)

    let exported = try settings.macros.exported()
    let imported = try Macros(importing: exported)
    #expect(imported == settings.macros)
}

@Test func corruptSettingsFallBackToDefaultsAndAreKept() throws {
    let url = temporaryFile()
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try Data("{not json".utf8).write(to: url)
    #expect(SettingsStore(url: url).load() == Settings())
    let kept = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)
    #expect(kept.contains { $0.hasPrefix("settings.json.corrupt") })
}
