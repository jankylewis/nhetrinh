import Foundation

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
        case .pressure(let level): return try line(["op": "pressure", "text": level.rawValue])
        case .find(let text): return try line(["op": "find", "text": text])
        case .setting(let name, let value): return try line(["op": "setting", "name": name, "text": value])
        case .middleClick(let row): return try line(["op": "middleClick", "index": row])
        case .commandClickLink: return try line(["op": "commandClickLink"])
        case .download(let row, let item): return try line(["op": "download", "index": row, "text": item])
        case .window(let item): return try line(["op": "window", "text": item])
        case .type(let text): return try line(["op": "type", "text": text])
        case .key(let name): return try line(["op": "key", "text": name])
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
        case ("pressure", let text, _): return .pressure(try level(text, of: line))
        case ("find", .some(let text), _): return .find(text)
        case ("setting", .some(let value), _): return try setting(value, object: object, line: line)
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
        case ("window", .some(let item), _) where !item.isEmpty: return .window(item)
        case ("type", .some(let text), _): return .type(text)
        case ("key", .some(let name), _) where !name.isEmpty: return .key(name)
        case ("menu", _, _): return .menu(try path(object, of: line))
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

    private static func setting(_ value: String, object: [String: Any], line: String) throws -> ProbeRequest {
        guard let name = object["name"] as? String, !name.isEmpty else { throw Failure.malformed(line) }
        return .setting(name: name, value: value)
    }

    /// A menu item's path; a missing or empty one is malformed.
    private static func path(_ object: [String: Any], of line: String) throws -> [String] {
        guard let path = object["path"] as? [String], !path.isEmpty else { throw Failure.malformed(line) }
        return path
    }

    /// A pressure level by its name (P6); an unknown or missing one is malformed, never guessed.
    private static func level(_ name: String?, of line: String) throws -> UnloadPolicy.Pressure {
        guard let level = name.flatMap(UnloadPolicy.Pressure.init) else { throw Failure.malformed(line) }
        return level
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
