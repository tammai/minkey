import Foundation
import Testing

@testable import MinkeyKit

@Test func resumesWordAfterDeletingIntoIt() {
    let client = FakeClient()
    let delivery = Delivery()
    delivery.activate(client)
    _ = send(letters("tieengs "), to: delivery, client: client)
    #expect(client.text == "tiếng ")
    _ = send([.delete, .delete, .delete], to: delivery, client: client)
    #expect(client.text == "tiế")

    _ = send(letters("ngf"), to: delivery, client: client)
    #expect(client.text == "tiềng")

    let unstable = FakeClient("tiế")
    unstable.unstableReads = true
    let other = Delivery()
    other.activate(unstable)
    #expect(send([.letter("n")], to: other, client: unstable) == [false])
    #expect(unstable.text == "tiến")
}
