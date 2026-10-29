import Foundation

/// One edit minkey made: where, in which app and mode, and how much text it put there, never what.
public struct EditRecord: Sendable {
    public var app: String
    public var mode: DeliveryMode
    public var range: NSRange
    public var insertedLength: Int
}

/// A troubleshooting log of edits, off by default, that switches itself off after a day.
public final class DiagnosticLog {
    public let url: URL
    private let now: () -> Date

    public init(url: URL, now: @escaping () -> Date = Date.init) {
        self.url = url
        self.now = now
    }

    static let lifetime: TimeInterval = 24 * 60 * 60
    private var enabledUntil: Date?

    public var isEnabled: Bool {
        guard let enabledUntil else { return false }
        return now() < enabledUntil
    }

    public func enable() {
        enabledUntil = now().addingTimeInterval(Self.lifetime)
    }

    public func disable() {
        enabledUntil = nil
    }

    public func record(_ edit: EditRecord) {
        guard isEnabled else { return }
        let time = ISO8601DateFormatter().string(from: now())
        let line =
            "\(time) app=\(edit.app) mode=\(edit.mode.rawValue) "
            + "range={\(edit.range.location), \(edit.range.length)} inserted=\(edit.insertedLength)\n"
        guard let data = line.data(using: .ascii) else { return }
        if let handle = try? FileHandle(forWritingTo: url) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: url)
        }
    }
}
