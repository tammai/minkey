import Foundation

enum Shape: Sendable {
    case plain, hat, breve, horn
}

enum Tone: Sendable {
    case none, acute, grave, hook, tilde, dot
}

/// One letter of the word being typed, kept decomposed so shape and tone can change independently.
struct Letter: Sendable {
    var base: Character
    var shape: Shape = .plain
    var tone: Tone = .none
    var isUpper: Bool

    init(_ key: Character) {
        base = Character(key.lowercased())
        isUpper = key.isUppercase
    }

    var isVowel: Bool { "aeiouy".contains(base) }

    var rendered: String {
        var text = String(base)
        switch shape {
        case .plain: break
        case .hat: text += "\u{0302}"
        case .breve: text += "\u{0306}"
        case .horn: text += "\u{031B}"
        }
        switch tone {
        case .none: break
        case .acute: text += "\u{0301}"
        case .grave: text += "\u{0300}"
        case .hook: text += "\u{0309}"
        case .tilde: text += "\u{0303}"
        case .dot: text += "\u{0323}"
        }
        text = text.precomposedStringWithCanonicalMapping
        return isUpper ? text.uppercased() : text
    }
}

extension Letter {
    /// Splits a precomposed letter such as `Ở` into base, shape, tone and case.
    init(precomposed: Character) {
        let scalars = String(precomposed).decomposedStringWithCanonicalMapping.unicodeScalars
        self.init(Character(scalars.first!))
        for mark in scalars.dropFirst() {
            switch mark {
            case "\u{0302}": shape = .hat
            case "\u{0306}": shape = .breve
            case "\u{031B}": shape = .horn
            case "\u{0301}": tone = .acute
            case "\u{0300}": tone = .grave
            case "\u{0309}": tone = .hook
            case "\u{0303}": tone = .tilde
            case "\u{0323}": tone = .dot
            default: break
            }
        }
    }
}
