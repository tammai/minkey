import AppKit
import MinkeyKit

/// The saved settings, applied to the shared delivery and saved again whenever they change.
@MainActor final class AppState: ObservableObject {
    static let shared = AppState()

    private let store: SettingsStore
    let diagnostics: DiagnosticLog

    /// Set when the last change couldn't be saved, so the window can say it will be lost on restart.
    @Published private(set) var saveFailed = false

    @Published var settings: Settings {
        didSet {
            apply()
            do {
                try store.save(settings)
                saveFailed = false
            } catch {
                saveFailed = true
            }
        }
    }

    private init() {
        let fileManager = FileManager.default
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let logs = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0].appendingPathComponent("Logs")
        store = SettingsStore(url: support.appendingPathComponent("minkey/settings.json"))
        diagnostics = DiagnosticLog(url: logs.appendingPathComponent("minkey-diagnostics.log"))
        settings = store.load()
        apply()
        delivery.onEdit = { [diagnostics] in diagnostics.record($0) }
    }

    private func apply() {
        delivery.engine.toneStyle = settings.toneStyle
        delivery.engine.spellCheck = settings.spellCheck
        delivery.macros = settings.macros
        delivery.languages = settings.languages
        delivery.overrides = settings.overrides
    }

    /// Saves the language the delivery just switched an app to.
    func languageToggled() {
        settings.languages = delivery.languages
    }
}
