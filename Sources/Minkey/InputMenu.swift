import AppKit
import InputMethodKit
import MinkeyKit

extension InputController {
    override func menu() -> NSMenu! {
        let menu = NSMenu()
        let toggleTitle =
            delivery.language == .vietnamese
            ? String(localized: "Switch to English") : String(localized: "Switch to Vietnamese")
        let toggle = NSMenuItem(title: toggleTitle, action: #selector(toggleLanguage(_:)), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        let settings = NSMenuItem(
            title: String(localized: "Settings…"), action: #selector(showSettings(_:)), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        if MainActor.assumeIsolated({ Updater.isAvailable }) {
            let update = NSMenuItem(
                title: String(localized: "Check for Updates…"), action: #selector(checkForUpdates(_:)),
                keyEquivalent: "")
            update.target = self
            menu.addItem(update)
        }
        return menu
    }

    @objc func toggleLanguage(_ sender: Any?) {
        guard let client = client() else { return }
        delivery.toggleLanguage(IMKTextClient(client))
        MainActor.assumeIsolated { AppState.shared.languageToggled() }
    }

    @objc func checkForUpdates(_ sender: Any?) {
        MainActor.assumeIsolated { Updater.checkForUpdates() }
    }

    @objc func showSettings(_ sender: Any?) {
        MainActor.assumeIsolated { SettingsWindow.show() }
    }

    /// True when `event` is the user's Vietnamese/English shortcut.
    func isToggleShortcut(_ event: NSEvent) -> Bool {
        let shortcut = MainActor.assumeIsolated { AppState.shared.settings.toggleShortcut }
        let relevant: NSEvent.ModifierFlags = [.shift, .control, .option, .command]
        return event.keyCode == shortcut.keyCode
            && UInt(event.modifierFlags.intersection(relevant).rawValue) == shortcut.modifiers
    }
}
