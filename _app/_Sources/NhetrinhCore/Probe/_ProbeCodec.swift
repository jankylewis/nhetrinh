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
    /// A left click on the first element the CSS selector finds in the selected page (P3).
    case click(String)
    /// The window's sheet: press its button `label` (P3: a page dialog, the open or print panel).
    case sheetButton(String)
    /// The window's sheet: type `text` into its text field `index` (0 first), as a user replaces it (P3).
    case sheetField(index: Int, text: String)
    /// Bring nhetrinh to the front and take the focus: only R26a and R26b, only with `--allow-focus` (D25).
    case front
    /// The find bar's field: `text` typed, then Return, as a user searches (P4, R27).
    case find(String)
    /// The Settings Hub's control `name` set to `value` as a user picks it ("Search engine", "DuckDuckGo") (P4).
    case setting(name: String, value: String)
    /// A middle click on a sidebar row (R13).
    case middleClick(row: Int)
    /// A ⌘-click on the first link in the selected page (R17).
    case commandClickLink
    /// The download row `row` (0 top) in the sidebar footer: "Cancel" pressed, or the row clicked
    /// ("Show in Finder") (P5).
    case download(row: Int, item: String)
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
        case .click(let selector): return try line(["op": "click", "text": selector])
        case .sheetButton(let label): return try line(["op": "sheetButton", "text": label])
        case .sheetField(let index, let text): return try line(["op": "sheetField", "index": index, "text": text])
        case .front: return try line(["op": "front"])
        case .find(let text): return try line(["op": "find", "text": text])
        case .setting(let name, let value): return try line(["op": "setting", "name": name, "text": value])
        case .middleClick(let row): return try line(["op": "middleClick", "index": row])
        case .commandClickLink: return try line(["op": "commandClickLink"])
        case .download(let row, let item): return try line(["op": "download", "index": row, "text": item])
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
        case ("front", _, _): return .front
        case ("find", .some(let text), _): return .find(text)
        case ("setting", .some(let value), _):
            guard let name = object["name"] as? String, !name.isEmpty else { throw Failure.malformed(line) }
            return .setting(name: name, value: value)
        case ("select", _, .some(let index)) where index >= 0: return .select(index)
        case (let op, .some(let item), .some(let row)) where ["rowMenu", "download"].contains(op) && row >= 0
            && !item.isEmpty: return op == "download" ? .download(row: row, item: item) : .rowMenu(row: row, item: item)
        case ("linkMenu", .some(let item), _) where !item.isEmpty: return .linkMenu(item: item)
        case ("button", .some(let label), _) where !label.isEmpty: return .button(label)
        case ("click", .some(let selector), _) where !selector.isEmpty: return .click(selector)
        case ("sheetButton", .some(let label), _) where !label.isEmpty: return .sheetButton(label)
        case ("sheetField", .some(let text), .some(let index)) where index >= 0:
            return .sheetField(index: index, text: text)
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
