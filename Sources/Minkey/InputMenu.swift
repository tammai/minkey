import AppKit
import InputMethodKit
import MinkeyKit

extension InputController {
    override func menu() -> NSMenu! {
        let menu = NSMenu()
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

    @objc func checkForUpdates(_ sender: Any?) {
        MainActor.assumeIsolated { Updater.checkForUpdates() }
    }

    @objc func showSettings(_ sender: Any?) {
        MainActor.assumeIsolated { SettingsWindow.show() }
    }
}
