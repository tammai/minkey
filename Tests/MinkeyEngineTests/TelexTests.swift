import Testing

@testable import MinkeyEngine

func typed(_ keys: String, style: ToneStyle = .new) -> String {
    var engine = TelexEngine(toneStyle: style)
    for key in keys { engine.type(key) }
    return engine.word
}

@Test(arguments: [
    ("aa", "â"), ("ee", "ê"), ("oo", "ô"), ("aw", "ă"), ("ow", "ơ"), ("uw", "ư"), ("dd", "đ"), ("w", "ư"),
    ("tw", "tư"), ("as", "á"), ("af", "à"), ("ar", "ả"), ("ax", "ã"), ("aj", "ạ"), ("asz", "a"),
    ("tieengs", "tiếng"), ("tieesng", "tiếng"), ("tiengse", "tiếng"),
    ("dduwowcj", "được"), ("duocwdj", "được"), ("nguowif", "người"), ("truwowngf", "trường"),
    ("hoawcj", "hoặc"), ("quas", "quá"), ("quys", "quý"), ("gif", "gì"), ("mufa", "mùa"), ("muwas", "mứa"),
    ("khoong", "không"), ("tooi", "tôi"), ("hoaif", "hoài"), ("hoangf", "hoàng"), ("thuyeenf", "thuyền"),
    ("Vieetj", "Việt"), ("DDaay", "Đây"), ("VIEETJ", "VIỆT"),
    ("hoaf", "hoà"), ("thuys", "thuý"), ("hoef", "hoè"),
])
func telexWords(keys: String, expected: String) {
    #expect(typed(keys) == expected)
}

@Test func telexWordsOldStyle() {
    #expect(typed("hoaf", style: .old) == "hòa")
    #expect(typed("thuys", style: .old) == "thúy")
    #expect(typed("hoangf", style: .old) == "hoàng")
}

@Test(arguments: [
    ("ass", "as"), ("aaa", "aa"), ("ddd", "dd"), ("uww", "uw"), ("asff", "af"), ("afff", "aff"), ("assf", "asf"),
    ("tieengss", "tiêngs"), ("fff", "fff"),
])
func undoTypesKeyAndStaysLiteral(keys: String, expected: String) {
    #expect(typed(keys) == expected)
}

@Test func deleteBackwardRemovesLastLetter() {
    var engine = TelexEngine()
    for key in "tieengs" { engine.type(key) }
    engine.deleteBackward()
    #expect(engine.word == "tiến")
    engine.type("g")
    #expect(engine.word == "tiếng")
}
