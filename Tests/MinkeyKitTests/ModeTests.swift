import Foundation
import Testing

@testable import MinkeyKit

@Test func teamsEditsInPlaceEvenWhenItCannotReadBack() {
    let teams = FakeClient(bundleID: "com.microsoft.teams2")
    teams.isTerminal = true
    let delivery = Delivery()
    delivery.activate(teams)
    #expect(delivery.mode == .direct)
}

@Test(arguments: ["com.stablyai.orca", "com.apple.Terminal", "com.googlecode.iterm2"])
func terminalsUseMarkedTextEvenWhenTheirCursorLooksReadable(bundleID: String) {
    let delivery = Delivery()
    delivery.activate(FakeClient("", bundleID: bundleID))
    #expect(delivery.mode == .marked)
}
