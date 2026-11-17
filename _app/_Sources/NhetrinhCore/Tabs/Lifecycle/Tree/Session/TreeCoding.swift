import Foundation

// How the tree is written in `session.json` (P7 version 2, P8-GROUPS-1 version 3). Tests:
// TreeSessionTests.swift and GroupSessionTests.swift with the files of SessionFixtures.swift.

/// An item is `{"tab": …}` or `{"folder": …}`; anything else is refused.
extension Tree.Item: Codable where Element: Codable {
    private enum Key: String, CodingKey { case tab, folder }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        if let tab = try container.decodeIfPresent(Element.self, forKey: .tab) {
            self = .tab(tab)
        } else {
            self = .folder(try container.decode(TreeFolder<Element>.self, forKey: .folder))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .tab(let tab): try container.encode(tab, forKey: .tab)
        case .folder(let folder): try container.encode(folder, forKey: .folder)
        }
    }
}

/// A group is `{"name", "collapsed", "items": [item…]}` (version 3). Version 2's `"tabs"` decodes as tabs
/// only, so a version 2 folder inside a folder is refused.
extension TreeFolder: Codable where Element: Codable {
    private enum Key: String, CodingKey { case name, collapsed, items, tabs }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let name = try container.decode(String.self, forKey: .name)
        let collapsed = try container.decode(Bool.self, forKey: .collapsed)
        if let items = try container.decodeIfPresent([Tree<Element>.Item].self, forKey: .items) {
            self.init(name: name, collapsed: collapsed, items: items)
        } else {
            self.init(name: name, collapsed: collapsed, tabs: try container.decode([Element].self, forKey: .tabs))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(name, forKey: .name)
        try container.encode(collapsed, forKey: .collapsed)
        try container.encode(items, forKey: .items)
    }
}

/// A path is written as its indexes, `[1, 0, 2]` (version 3); version 2's `{"item": 1, "tab": 0}` is read.
extension TabPath: Codable {
    private enum Key: String, CodingKey { case item, tab }

    public init(from decoder: Decoder) throws {
        if let indexes = try? decoder.singleValueContainer().decode([Int].self) {
            guard !indexes.isEmpty else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "no index"))
            }
            self.init(indexes)
            return
        }
        let container = try decoder.container(keyedBy: Key.self)
        self.init(item: try container.decode(Int.self, forKey: .item),
                  tab: try container.decodeIfPresent(Int.self, forKey: .tab))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(indexes)
    }
}
