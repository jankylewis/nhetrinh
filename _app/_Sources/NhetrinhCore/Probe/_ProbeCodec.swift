import Foundation

/// A readback probe request (D23). One JSON object per line, one request per connection.
public enum ProbeRequest: Equatable, Sendable {
    case state
    case navigate(String)
    case newTab
    case closeTab
    case select(Int)
    /// A menu item by its path, ["Tabs", "Back"], performed as a click on it once the answer is sent.
    case menu([String])
    /// A sidebar row's menu, shown on that row, and its item `item` pressed (R13).
    case rowMenu(row: Int, item: String)
    /// The context menu of the first link in the selected page, and its item `item` pressed (R17).
    case linkMenu(item: String)
    /// A toolbar button by its label ("Stop"), pressed (R18).
    case button(String)
    /// A middle click on a sidebar row (R13).
    case middleClick(row: Int)
    /// A ⌘-click on the first link in the selected page (R17).
    case commandClickLink
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
        case .menu(let path): return try line(["op": "menu", "path": path])
        case .rowMenu(let row, let item): return try line(["op": "rowMenu", "index": row, "text": item])
        case .linkMenu(let item): return try line(["op": "linkMenu", "text": item])
        case .button(let label): return try line(["op": "button", "text": label])
        case .middleClick(let row): return try line(["op": "middleClick", "index": row])
        case .commandClickLink: return try line(["op": "commandClickLink"])
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
        case ("rowMenu", .some(let item), .some(let row)) where row >= 0 && !item.isEmpty:
            return .rowMenu(row: row, item: item)
        case ("linkMenu", .some(let item), _) where !item.isEmpty: return .linkMenu(item: item)
        case ("button", .some(let label), _) where !label.isEmpty: return .button(label)
        case ("middleClick", _, .some(let row)) where row >= 0: return .middleClick(row: row)
        case ("commandClickLink", _, _): return .commandClickLink
        case ("menu", _, _):
            guard let path = object["path"] as? [String], !path.isEmpty else { throw Failure.malformed(line) }
            return .menu(path)
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
