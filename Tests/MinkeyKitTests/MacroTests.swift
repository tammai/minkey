import Foundation
import Testing

@testable import MinkeyKit

@Test func macroExpandsFollowingCase() {
    let macros = Macros(entries: ["btw": "by the way", "ko": "không"])
    #expect(macros.expand("btw") == "by the way")
    #expect(macros.expand("Btw") == "By the way")
    #expect(macros.expand("BTW") == "BY THE WAY")
    #expect(macros.expand("bt") == nil)
    let imported = try? Macros(importing: Data(#"{"entries":{"BTW":"by the way"},"inEnglishMode":false}"#.utf8))
    #expect(imported?.expand("btw") == "by the way")

    let client = FakeClient()
    let delivery = Delivery()
    delivery.macros = macros
    delivery.activate(client)
    _ = send(letters("Btw ko "), to: delivery, client: client)
    #expect(client.text == "By the way không ")

    delivery.toggleLanguage(client)
    _ = send(letters("btw "), to: delivery, client: client)
    #expect(client.text == "By the way không btw ")

    delivery.macros.inEnglishMode = true
    _ = send(letters("btw "), to: delivery, client: client)
    #expect(client.text == "By the way không btw by the way ")
}
