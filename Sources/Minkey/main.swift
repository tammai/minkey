import AppKit
import Carbon
import InputMethodKit

if CommandLine.arguments.contains("--version") {
    print(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
    exit(0)
}

if CommandLine.arguments.contains("--install") {
    // Registers this bundle with Text Input Sources and enables its Telex mode, so no logout is needed.
    let url = Bundle.main.bundleURL as CFURL
    guard TISRegisterInputSource(url) == noErr else { exit(1) }
    let filter = [kTISPropertyBundleID as String: Bundle.main.bundleIdentifier ?? ""] as CFDictionary
    let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] ?? []
    for source in sources { TISEnableInputSource(source) }
    exit(0)
}

/// Opening the app again (`open` on its bundle) shows Settings, for when the input menu has no minkey items.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindow.show()
        return false
    }
}

_ = AppState.shared
Updater.start()
let connection = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "Minkey_Connection"
let server = IMKServer(name: connection, bundleIdentifier: Bundle.main.bundleIdentifier)
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
withExtendedLifetime((server, delegate)) {
    NSApplication.shared.run()
}
