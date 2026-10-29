import Foundation

public enum Language: String, Codable, Sendable {
    case vietnamese, english
}

/// Which language each app was last left in.
public struct AppLanguages: Codable, Equatable, Sendable {
    public var chosen: [String: Language]

    /// Terminals and code editors, where most typing is commands and code.
    static let englishByDefault: Set<String> = [
        "com.apple.Terminal", "com.googlecode.iterm2", "dev.warp.Warp-Stable", "net.kovidgoyal.kitty",
        "com.mitchellh.ghostty", "org.alacritty", "com.github.wez.wezterm", "com.stablyai.orca",
        "com.microsoft.VSCode", "com.todesktop.230313mzl4w4u92", "com.apple.dt.Xcode", "dev.zed.Zed",
        "com.sublimetext.4",
    ]

    public init(chosen: [String: Language] = [:]) {
        self.chosen = chosen
    }

    public func language(for app: String) -> Language {
        if let language = chosen[app] { return language }
        return Self.englishByDefault.contains(app) || app.hasPrefix("com.jetbrains.") ? .english : .vietnamese
    }
}
