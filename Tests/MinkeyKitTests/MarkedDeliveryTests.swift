import Foundation
import Testing

@testable import MinkeyKit

@Test func clientWithoutTextGetsMarkedMode() {
    let terminal = FakeClient(bundleID: "com.example.terminal")
    terminal.isTerminal = true
    let delivery = Delivery()
    delivery.activate(terminal)
    #expect(delivery.mode == .marked)

    _ = send(letters("tieengs"), to: delivery, client: terminal)
    #expect(terminal.text == "tiếng")
    #expect(terminal.markedRange != nil)
    _ = send(letters(" "), to: delivery, client: terminal)
    #expect(terminal.text == "tiếng ")
    #expect(terminal.markedRange == nil)

    _ = send(letters("vieetj"), to: delivery, client: terminal)
    delivery.deactivate(terminal)
    #expect(terminal.text == "tiếng việt")
    #expect(terminal.markedRange == nil)

    let teams = FakeClient(bundleID: "com.microsoft.teams2")
    let forced = Delivery(overrides: ["com.microsoft.teams2": .marked])
    forced.activate(teams)
    #expect(forced.mode == .marked)
}
