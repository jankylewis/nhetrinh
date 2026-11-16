import Foundation

/// Where the probe listens, and when (D23). Only `NHT_READBACK=1` turns it on; the socket is in a
/// folder of its own per process, under the user's own temporary folder (not shared with others).
public enum ProbePath {
    public static let variable = "NHT_READBACK"
    /// `sun_path` holds 104 bytes on macOS, the last one the terminating zero.
    public static let maxLength = 103

    public static func isOn(_ env: [String: String]) -> Bool { env[variable] == "1" }

    /// The user's temporary folder (`confstr`), the same for the app and the readback of one user.
    public static func userTemp() -> String {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        let length = confstr(_CS_DARWIN_USER_TEMP_DIR, &buffer, buffer.count)
        guard length > 0, length <= buffer.count else { return NSTemporaryDirectory() }
        let text = String(decoding: buffer.prefix(length - 1).map { UInt8(bitPattern: $0) }, as: UTF8.self)
        return text.hasSuffix("/") ? text : text + "/"
    }

    public static func folder(pid: Int32, temp: String = userTemp()) -> String {
        (temp.hasSuffix("/") ? temp : temp + "/") + "nhetrinh-probe-\(pid)"
    }

    public static func socket(pid: Int32, temp: String = userTemp()) -> String {
        folder(pid: pid, temp: temp) + "/probe.sock"
    }
}

/// The modifier keys of a shortcut.
public struct ShortcutKeys: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let control = ShortcutKeys(rawValue: 1)
    public static let option = ShortcutKeys(rawValue: 2)
    public static let shift = ShortcutKeys(rawValue: 4)
    public static let command = ShortcutKeys(rawValue: 8)
}

/// A shortcut as the menu shows it: modifiers in the order ⌃⌥⇧⌘, then the key in capitals.
public enum Shortcut {
    public static func text(key: String, keys: ShortcutKeys) -> String {
        guard !key.isEmpty else { return "" }
        let marks: [(ShortcutKeys, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return marks.filter { keys.contains($0.0) }.map(\.1).joined() + key.uppercased()
    }
}
