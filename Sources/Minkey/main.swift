import AppKit
import Carbon
import InputMethodKit

if CommandLine.arguments.contains("--install") {
    // Registers this bundle with Text Input Sources and enables its Telex mode, so no logout is needed.
    let url = Bundle.main.bundleURL as CFURL
    guard TISRegisterInputSource(url) == noErr else { exit(1) }
    let filter = [kTISPropertyBundleID as String: Bundle.main.bundleIdentifier ?? ""] as CFDictionary
    let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] ?? []
    for source in sources { TISEnableInputSource(source) }
    exit(0)
}

_ = AppState.shared
let connection = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String ?? "Minkey_Connection"
let server = IMKServer(name: connection, bundleIdentifier: Bundle.main.bundleIdentifier)
withExtendedLifetime(server) {
    NSApplication.shared.run()
}
