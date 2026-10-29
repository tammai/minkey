import Foundation
import Testing

@testable import MinkeyKit

@Test func directModeReplacesOnlyChangedCharacters() {
    let client = FakeClient("Hi ")
    client.lagsReads = true
    let delivery = Delivery()
    delivery.activate(client)

    let handled = send(letters("tieeng"), to: delivery, client: client)
    #expect(handled.allSatisfy { $0 })
    #expect(delivery.mode == .direct)
    _ = send([.letter("s")], to: delivery, client: client)
    #expect(client.edits.last?.range == NSRange(location: 5, length: 3))
    #expect(client.edits.last?.text == "ếng")

    _ = send([.delete, .delete], to: delivery, client: client)
    #expect(client.text == "Hi tiế")
    _ = send(letters("ng "), to: delivery, client: client)
    #expect(client.text == "Hi tiếng ")
    #expect(client.markedRange == nil)

    _ = send(letters("vieetj nhes"), to: delivery, client: client)
    #expect(delivery.mode == .direct)
    #expect(client.text == "Hi tiếng việt nhé")
}

@Test func passedThroughKeysDoNotStopTypingInLaggingApps() {
    let client = FakeClient()
    client.lagsReads = true
    let delivery = Delivery()
    delivery.activate(client)
    _ = send(letters("chaof"), to: delivery, client: client)
    _ = send([.boundary(","), .boundary(" ")], to: delivery, client: client)
    _ = send(letters("tieengs "), to: delivery, client: client)
    #expect(delivery.mode == .direct)
    #expect(client.text == "chào, tiếng ")
}

@Test func directModeRestoresEnglishAtBoundary() {
    let client = FakeClient()
    let delivery = Delivery()
    delivery.activate(client)
    _ = send(letters("with "), to: delivery, client: client)
    #expect(client.text == "with ")
}

@Test func trackingDropsOnUnexpectedCursor() {
    let client = FakeClient("abc ")
    let delivery = Delivery()
    delivery.activate(client)
    #expect(send(letters("tie"), to: delivery, client: client).allSatisfy { $0 })
    client.cursor = 0
    _ = send(letters("es"), to: delivery, client: client)
    #expect(client.text == "éabc tie")

    let focus = FakeClient("x ")
    delivery.activate(focus)
    #expect(send(letters("tie"), to: delivery, client: focus).allSatisfy { $0 })
    delivery.deactivate(focus)
    focus.cursor = 0
    delivery.activate(focus)
    _ = send([.letter("s")], to: delivery, client: focus)
    #expect(focus.text == "sx tie")

    let long = FakeClient()
    delivery.activate(long)
    let handled = send(Array(repeating: .letter("a"), count: 40), to: delivery, client: long)
    #expect(handled.prefix(5).allSatisfy { $0 })
    #expect(handled.suffix(5).allSatisfy { !$0 })
}
