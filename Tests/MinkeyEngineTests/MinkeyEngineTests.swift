import Testing
@testable import MinkeyEngine

@Test func engineHasVersion() {
    #expect(!MinkeyEngine.version.isEmpty)
}
