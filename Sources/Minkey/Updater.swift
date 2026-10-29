import Foundation
import Sparkle

@MainActor enum Updater {
    private static var controller: SPUStandardUpdaterController?

    /// Only release builds carry the update signing key; development builds never check for updates.
    static func start() {
        guard Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") != nil else { return }
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    static var isAvailable: Bool { controller != nil }

    static func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
