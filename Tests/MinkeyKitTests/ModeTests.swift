import Foundation
import Testing

@testable import MinkeyKit

@Test func perAppModeAndToggle() {
    let notes = FakeClient(bundleID: "com.apple.Notes")
    let teams = FakeClient(bundleID: "com.microsoft.teams2")
    let terminal = FakeClient(bundleID: "com.apple.Terminal")
    let delivery = Delivery()

    delivery.activate(notes)
    #expect(delivery.language == .vietnamese)
    delivery.toggleLanguage(notes)
    #expect(delivery.language == .english)
    #expect(send(letters("tieengs"), to: delivery, client: notes).allSatisfy { !$0 })
    #expect(notes.text == "tieengs")

    delivery.activate(teams)
    #expect(delivery.language == .vietnamese)
    _ = send(letters("tieengs"), to: delivery, client: teams)
    #expect(teams.text == "tiếng")

    delivery.activate(notes)
    #expect(delivery.language == .english)
    delivery.activate(terminal)
    #expect(delivery.language == .english)
    #expect(delivery.languages.chosen["com.apple.Notes"] == .english)
}
