import ApplicationServices

/// One element of an app's accessibility tree: the same tree VoiceOver and Voice Control use.
/// The readback acts through it (press, set a value, confirm). It never moves the mouse and
/// never types on the keyboard, so nothing it does can land in another app.
struct AXNode {
    let element: AXUIElement

    static var isTrusted: Bool { AXIsProcessTrusted() }

    static func application(pid: pid_t) -> AXNode {
        AXNode(element: AXUIElementCreateApplication(pid))
    }

    // MARK: - Read

    private func raw(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    /// The accessibility error of reading `name`, `.success` when it reads: why a read is empty.
    func readError(_ name: String) -> AXError {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value)
    }

    func string(_ name: String) -> String { raw(name) as? String ?? "" }
    func number(_ name: String) -> Int? { raw(name) as? Int }
    func nodes(_ name: String) -> [AXNode] { (raw(name) as? [AXUIElement] ?? []).map(AXNode.init) }

    func flag(_ name: String) -> Bool { raw(name) as? Bool ?? false }
    var url: URL? { raw(kAXURLAttribute) as? URL }

    func node(_ name: String) -> AXNode? {
        guard let value = raw(name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return AXNode(element: value as! AXUIElement)  // force: the CF type is checked on the line above
    }

    var role: String { string(kAXRoleAttribute) }
    var title: String { string(kAXTitleAttribute) }
    var value: String { string(kAXValueAttribute) }
    var identifier: String { string("AXIdentifier") }
    var children: [AXNode] { nodes(kAXChildrenAttribute) }
    var rows: [AXNode] { nodes(kAXRowsAttribute) }
    var windows: [AXNode] { nodes(kAXWindowsAttribute) }

    /// Position and size on screen, in points, origin at the top left.
    var frame: CGRect? {
        guard let position = raw(kAXPositionAttribute), let size = raw(kAXSizeAttribute),
              CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var origin = CGPoint.zero, extent = CGSize.zero
        AXValueGetValue(position as! AXValue, .cgPoint, &origin)  // force: the CF type is checked above
        AXValueGetValue(size as! AXValue, .cgSize, &extent)  // force: the CF type is checked above
        return CGRect(origin: origin, size: extent)
    }

    /// The first element at or below this one (depth first) that satisfies `match`.
    func first(depth: Int = 14, where match: (AXNode) -> Bool) -> AXNode? {
        if match(self) { return self }
        guard depth > 0 else { return nil }
        for child in children {
            if let found = child.first(depth: depth - 1, where: match) { return found }
        }
        return nil
    }

    func find(id: String) -> AXNode? { first { $0.identifier == id } }

    /// A menu item by its path from the menu bar, for example ["File", "New Tab"].
    func menuItem(_ path: [String]) -> AXNode? {
        var node = self.node(kAXMenuBarAttribute)
        for title in path {
            node = node?.children.lazy.compactMap { $0.first(depth: 2) { $0.title == title } }.first
        }
        return node
    }

    /// The keyboard shortcut of a menu item as text, for example "⌘T" or "⇧⌘T"; "" when it has none.
    var shortcut: String {
        let key = string("AXMenuItemCmdChar")
        guard !key.isEmpty, let modifiers = number("AXMenuItemCmdModifiers") else { return "" }
        let shift = modifiers & 1 != 0 ? "⇧" : "", option = modifiers & 2 != 0 ? "⌥" : ""
        let control = modifiers & 4 != 0 ? "⌃" : "", command = modifiers & 8 == 0 ? "⌘" : ""
        return control + option + shift + command + key
    }

    // MARK: - Act

    func press() throws { try perform(kAXPressAction) }
    func confirm() throws { try perform(kAXConfirmAction) }

    func set(_ name: String, to value: CFTypeRef) throws {
        let error = AXUIElementSetAttributeValue(element, name as CFString, value)
        guard error == .success else {
            throw StepError.cannotDrive("cannot set \(name) (accessibility error \(error.rawValue))")
        }
    }

    private func perform(_ action: String) throws {
        let error = AXUIElementPerformAction(element, action as CFString)
        guard error == .success else {
            throw StepError.cannotDrive("cannot perform \(action) (accessibility error \(error.rawValue))")
        }
    }
}

extension WindowRead {
    /// Read `window` once more, for the reason of a step that did not find an element in it.
    init(_ window: AXNode, roles: Int = 3) {
        let children = window.children
        self.init(title: window.title, children: children.count, firstRoles: children.prefix(roles).map(\.role),
                  error: window.readError(kAXChildrenAttribute).rawValue,
                  hasOwnID: window.first { $0.identifier.hasPrefix(EmptyReads.ownPrefix) } != nil)
    }
}
