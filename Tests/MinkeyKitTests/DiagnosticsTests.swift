import Foundation
import Testing

@testable import MinkeyKit

@Test func diagnosticLogMasksLettersAndExpires() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("minkey-\(UUID().uuidString).log")
    nonisolated(unsafe) var now = Date(timeIntervalSince1970: 1_800_000_000)
    let log = DiagnosticLog(url: url, now: { now })
    log.enable()
    #expect(log.isEnabled)

    let client = FakeClient("Hi ", bundleID: "com.microsoft.teams2")
    let delivery = Delivery()
    delivery.onEdit = log.record
    delivery.activate(client)
    _ = send(letters("tieengs "), to: delivery, client: client)

    let text = try String(contentsOf: url, encoding: .utf8)
    #expect(text.contains("app=com.microsoft.teams2"))
    #expect(text.contains("mode=direct"))
    #expect(text.contains("range={"))
    #expect(text.unicodeScalars.allSatisfy { $0.isASCII })
    #expect(!text.contains("tie") && !text.contains("Hi"))

    now += 24 * 60 * 60 + 1
    #expect(!log.isEnabled)
    _ = send(letters("ddi "), to: delivery, client: client)
    let after = try String(contentsOf: url, encoding: .utf8)
    #expect(after == text)
}
