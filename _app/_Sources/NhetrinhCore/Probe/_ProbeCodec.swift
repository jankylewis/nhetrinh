import Foundation

/// A readback probe request (D23). One JSON object per line, one request per connection.
public enum ProbeRequest: Equatable, Sendable {
    case state
    case navigate(String)
    case newTab
    case closeTab
    case select(Int)
}

/// What the app shows, as the readback needs it (R1, R3-R7). Every field has a default, so an
/// answer from an older app still decodes; the readback then sees the default and says so.
public struct ProbeState: Equatable, Sendable {
    public var title = ""
    /// The sidebar rows, top to bottom, as the table shows them.
    public var rows: [String] = []
    /// The selected sidebar row; nil when none is selected.
    public var selected: Int?
    /// The text in the address field.
    public var address = ""
    public var windowShown = false
    public var sidebarWidth = 0.0
    public var addressShown = false
    /// Menu item path ("File > New Tab") to its shortcut as the menu shows it ("⌘T").
    public var shortcuts: [String: String] = [:]

    public init() {}
}

public enum ProbeResponse: Equatable, Sendable {
    case state(ProbeState)
    case done
    case failed(String)
}

/// Encodes and decodes probe lines: one JSON object per line. Anything unknown or malformed
/// throws; nothing crashes. `JSONSerialization`, not `Codable`: it adds less code to the app.
public enum ProbeCodec {
    public enum Failure: Error, Equatable { case malformed(String) }

    public static func encode(_ request: ProbeRequest) throws -> String {
        switch request {
        case .state: return try line(["op": "state"])
        case .navigate(let text): return try line(["op": "navigate", "text": text])
        case .newTab: return try line(["op": "newTab"])
        case .closeTab: return try line(["op": "closeTab"])
        case .select(let index): return try line(["op": "select", "index": index])
        }
    }

    public static func encode(_ response: ProbeResponse) throws -> String {
        switch response {
        case .state(let state): return try line(["op": "state", "state": state.object])
        case .done: return try line(["op": "done"])
        case .failed(let reason): return try line(["op": "failed", "text": reason])
        }
    }

    public static func decodeRequest(_ line: String) throws -> ProbeRequest {
        let object = try decode(line)
        switch (object["op"] as? String, object["text"] as? String, object["index"] as? Int) {
        case ("state", _, _): return .state
        case ("navigate", .some(let text), _): return .navigate(text)
        case ("newTab", _, _): return .newTab
        case ("closeTab", _, _): return .closeTab
        case ("select", _, .some(let index)) where index >= 0: return .select(index)
        default: throw Failure.malformed(line)
        }
    }

    public static func decodeResponse(_ line: String) throws -> ProbeResponse {
        let object = try decode(line)
        switch (object["op"] as? String, object["state"] as? [String: Any], object["text"] as? String) {
        case ("state", .some(let state), _): return .state(ProbeState(state))
        case ("done", _, _): return .done
        case ("failed", _, .some(let reason)): return .failed(reason)
        default: throw Failure.malformed(line)
        }
    }

    private static func line(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    private static func decode(_ line: String) throws -> [String: Any] {
        let data = Data(line.utf8)
        guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw Failure.malformed(line)
        }
        return object
    }
}

extension ProbeState {
    var object: [String: Any] {
        var object: [String: Any] = ["title": title, "rows": rows, "address": address, "windowShown": windowShown,
                                     "sidebarWidth": sidebarWidth, "addressShown": addressShown, "shortcuts": shortcuts]
        if let selected { object["selected"] = selected }
        return object
    }

    /// A field that is missing or of another type keeps its default: the readback then sees it.
    init(_ object: [String: Any]) {
        title = object["title"] as? String ?? ""
        rows = object["rows"] as? [String] ?? []
        selected = object["selected"] as? Int
        address = object["address"] as? String ?? ""
        windowShown = object["windowShown"] as? Bool ?? false
        sidebarWidth = object["sidebarWidth"] as? Double ?? 0
        addressShown = object["addressShown"] as? Bool ?? false
        shortcuts = object["shortcuts"] as? [String: String] ?? [:]
    }
}
