import Testing

@testable import MinkeyEngine

func ended(_ keys: String, spellCheck: Bool = true) -> String {
    var engine = TelexEngine(spellCheck: spellCheck)
    for key in keys { engine.type(key) }
    return engine.endWord()
}

@Test(arguments: [
    ("tuaanfw", "tuầnw"), ("tapf", "tapf"), ("class", "class"), ("mentions", "mentions"),
    ("duocd", "đuoc"), ("duongd", "đuong"), ("quatw", "quăt"), ("quowrn", "quởn"), ("oawc", "oăc"),
    ("tieengs", "tiếng"), ("hocj", "học"), ("hocf", "hocf"),
])
func invalidChangeTypesKeyLiterally(keys: String, expected: String) {
    #expect(typed(keys) == expected)
}

@Test(arguments: [
    ("class", "class"), ("mention", "mention"), ("mentions", "mentions"), ("with", "with"), ("With", "With"),
    ("tuaanfw", "tuaanfw"), ("is", "í"), ("iss", "is"), ("tieengs", "tiếng"), ("dduwowcj", "được"),
    ("aa", "aa"), ("oo", "ô"), ("ddaay", "đây"),
])
func invalidWordRestoresAtBoundary(keys: String, expected: String) {
    #expect(ended(keys) == expected)
}

@Test func spellCheckOffAppliesEveryKey() {
    #expect(ended("tuaanfw", spellCheck: false) == "tưần")
}

@Test func endWordStartsAFreshWord() {
    var engine = TelexEngine()
    for key in "class" { engine.type(key) }
    _ = engine.endWord()
    for key in "as" { engine.type(key) }
    #expect(engine.word == "á")
}

@Test(arguments: [
    ("nghieeng", "nghiêng"), ("thichs", "thích"), ("anh", "anh"), ("eechs", "ếch"), ("hoanhf", "hoành"),
    ("chuyeenj", "chuyện"), ("giuwowngf", "giường"), ("quyeenr", "quyển"), ("nuwowcs", "nước"),
    ("khueechs", "khuếch"), ("ngoafi", "ngoài"), ("khuya", "khuya"), ("ddeem", "đêm"), ("xengr", "xẻng"),
    ("loaij", "loại"), ("mootj", "một"), ("cuwar", "cửa"), ("bieeu", "biêu"), ("yeeus", "yếu"),
])
func commonWordsStayVietnamese(keys: String, expected: String) {
    #expect(ended(keys) == expected)
}
