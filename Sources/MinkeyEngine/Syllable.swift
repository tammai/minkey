import Foundation

/// Vietnamese syllable structure: onset, vowel cluster, coda, and which tones a stop coda allows.
enum Syllable {
    private enum CodaRule {
        case required, optional, none
    }

    private static let onsets: Set<String> = [
        "", "b", "c", "ch", "d", "đ", "g", "gh", "gi", "h", "k", "kh", "l", "m", "n", "ng", "ngh", "nh", "p", "ph",
        "qu", "r", "s", "t", "th", "tr", "v", "x",
    ]

    private static let clusters: [(vowels: [Letter], coda: CodaRule)] = [
        ("a", CodaRule.optional), ("ă", .required), ("â", .required), ("e", .optional), ("ê", .optional),
        ("i", .optional), ("o", .optional), ("ô", .optional), ("ơ", .optional), ("u", .optional), ("ư", .optional),
        ("y", .none), ("oa", .optional), ("oe", .optional), ("uê", .optional), ("uy", .optional),
        ("oă", .required), ("uâ", .required), ("iê", .required), ("yê", .required), ("uô", .required),
        ("ươ", .required), ("uyê", .required),
        ("ai", .none), ("ao", .none), ("au", .none), ("ay", .none), ("âu", .none), ("ây", .none), ("eo", .none),
        ("êu", .none), ("ia", .none), ("iu", .none), ("oi", .none), ("ôi", .none), ("ơi", .none), ("ua", .none),
        ("ui", .none), ("ưa", .none), ("ưi", .none), ("ưu", .none), ("uơ", .none), ("iêu", .none), ("yêu", .none),
        ("oai", .none), ("oay", .none), ("oeo", .none), ("uây", .none), ("uôi", .none), ("ươi", .none),
        ("ươu", .none), ("uya", .none), ("uyu", .none),
    ].map { (Array($0.0).map(Letter.init(precomposed:)), $0.1) }

    private static let codas: Set<String> = ["c", "ch", "m", "n", "ng", "nh", "p", "t"]
    private static let stopCodas: Set<String> = ["c", "ch", "p", "t"]
    private static let chNhClusters: Set<String> = ["a", "ê", "i", "oa", "uê", "uy"]
    /// After these, the velar coda is spelled `ch`/`nh`, never `c`/`ng`.
    private static let noCNgClusters: Set<String> = ["ê", "i", "uê", "uy"]

    /// A finished word that is a real Vietnamese syllable.
    static func isValid(_ letters: [Letter]) -> Bool { check(letters, complete: true) }

    /// A word that is still a valid syllable or can become one with more keys.
    static func canBecomeValid(_ letters: [Letter]) -> Bool { check(letters, complete: false) }

    private static func check(_ letters: [Letter], complete: Bool) -> Bool {
        let bases = letters.map { String($0.base) }
        var onsetEnd = letters.firstIndex(where: \.isVowel) ?? letters.count
        if onsetEnd == 1, bases.first == "q", bases.count > 1, bases[1] == "u" { onsetEnd = 2 }
        if onsetEnd == 1, bases.first == "g", bases.count > 2, bases[1] == "i", letters[2].isVowel { onsetEnd = 2 }
        let onset = bases[..<onsetEnd].joined()
        let vowelEnd = letters[onsetEnd...].firstIndex(where: { !$0.isVowel }) ?? letters.count
        let vowels = Array(letters[onsetEnd..<vowelEnd])
        let coda = bases[vowelEnd...].joined()

        if vowels.isEmpty {
            return !complete && onsets.contains { $0.hasPrefix(onset) }
        }
        guard onsets.contains(onset), letters[vowelEnd...].allSatisfy({ !$0.isVowel }) else { return false }
        if stopCodas.contains(where: { $0.hasPrefix(coda) }), !coda.isEmpty,
            ![.none, .acute, .dot].contains(letters.first(where: { $0.tone != .none })?.tone ?? .none)
        {
            return false
        }
        return clusters.contains { cluster in
            matches(vowels, cluster.vowels, complete: complete, open: coda.isEmpty)
                && codaFits(coda, cluster.coda, cluster.vowels, complete: complete)
        }
    }

    private static func matches(_ typed: [Letter], _ cluster: [Letter], complete: Bool, open: Bool) -> Bool {
        if complete || !open {
            guard typed.count == cluster.count else { return false }
        } else {
            guard typed.count <= cluster.count else { return false }
        }
        return zip(typed, cluster).allSatisfy { typed, wanted in
            typed.base == wanted.base && (typed.shape == wanted.shape || (!complete && typed.shape == .plain))
        }
    }

    private static func codaFits(_ coda: String, _ rule: CodaRule, _ cluster: [Letter], complete: Bool) -> Bool {
        if coda.isEmpty { return !complete || rule != .required }
        guard rule != .none else { return false }
        let candidates = complete ? codas.filter { $0 == coda } : codas.filter { $0.hasPrefix(coda) }
        let spelled = cluster.map(\.rendered).joined()
        return candidates.contains { candidate in
            switch candidate {
            case "ch", "nh": chNhClusters.contains(spelled)
            case "c", "ng": !noCNgClusters.contains(spelled)
            default: true
            }
        }
    }
}
