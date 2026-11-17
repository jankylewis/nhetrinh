import AppKit
import NhetrinhCore

/// P7 tab folders, nested groups since P8-GROUPS-1 (hubs/product/plan/M3_V1_RELEASE.md). The tree (`tree`)
/// is the tabs' order; every operation is `Tree`'s (NhetrinhCore, unit tested). A group's name is asked in
/// a sheet on the window; a refused operation shows the tree's reason in a sheet. Close Group: GroupClosing.
extension BrowserWindowController {
    /// The sidebar's items, groups with their items. A collapsed group that holds the selected tab is marked.
    var sidebarItems: [SidebarItem] {
        let chosen = tabs.indices.contains(selected) ? tabs[selected] : nil
        func shown(_ items: [Tree<Tab>.Item]) -> [SidebarItem] {
            items.map { item in
                switch item {
                case .tab(let tab): return .tab(SidebarView.Row(title: tab.title, loaded: tab.isLoaded, icon: tab.icon))
                case .folder(let group):
                    let inside = group.allTabs
                    let holds = inside.contains { $0 === chosen }
                    return .group(SidebarGroup(name: group.name, collapsed: group.collapsed,
                                               marked: group.collapsed && holds, count: inside.count,
                                               items: shown(group.items)))
                }
            }
        }
        return shown(tree.items)
    }

    /// Change the tabs' order; the selection stays on its tab, wherever the tab goes.
    func keepingSelection(_ change: () -> Void) {
        let chosen = tabs.indices.contains(selected) ? tabs[selected] : nil
        change()
        if let chosen, let index = tabs.firstIndex(where: { $0 === chosen }) { selected = index }
    }

    func sidebarAction(_ action: SidebarAction) {
        switch action {
        case .newGroup(let parent, let index):
            askName("New Group", button: "Create", name: "", unless: { try $0.checkNewGroup(in: parent) }) { name in
                { try $0.addGroup(named: name, in: parent, at: index) }
            }
        case .groupTab(let path):
            askName("New Group", button: "Create", name: "", unless: { try $0.wrap(path, inGroupNamed: "-") }) { name in
                { try $0.wrap(path, inGroupNamed: name) }
            }
        case .rename(let path):
            let name = (try? tree.group(at: path).name) ?? ""
            askName("Rename Group", button: "Rename", name: name, unless: { _ = try $0.group(at: path) }) { name in
                { try $0.rename(group: path, to: name) }
            }
        case .setCollapsed(let path, let collapsed): change { try $0.setCollapsed(collapsed, group: path) }
        case .ungroup(let path): change { try $0.ungroup(at: path) }
        case .closeGroup(let path): askToCloseGroup(at: path)
        case .move(let from, let parent, let index): change { try $0.move(from: from, into: parent, at: index) }
        }
    }

    /// Why the item at `from` cannot move into the group at `parent` at `index`; nil when it can.
    func moveRefusal(from: TabPath, into parent: [Int], at index: Int?) -> TreeFailure? {
        var copy = tree
        return refusal { try copy.move(from: from, into: parent, at: index) }
    }

    /// Apply `body` to the tree; when the tree refuses, its reason is shown and nothing changes.
    func change(_ body: (inout Tree<Tab>) throws -> Void) {
        var next = tree
        if let failure = refusal({ try body(&next) }) { return showRefusal(failure) }
        keepingSelection { tree = next }
        backgroundSlot = nil
        refreshChrome()
    }

    /// The reason of a refused operation, in a sheet with OK; the probe reads it (R49).
    func showRefusal(_ failure: TreeFailure) {
        Log.app.info("groups: refused (\(String(describing: failure), privacy: .public))")
        groupRefusal = failure.reason
        refreshChrome()
        let alert = NSAlert()
        alert.messageText = "Not done"
        alert.informativeText = failure.reason
        alert.addButton(withTitle: "OK")
        ask(alert, for: nil) { _ in }
    }

    private func refusal(_ body: () throws -> Void) -> TreeFailure? {
        do {
            try body()
            return nil
        } catch {
            return error as? TreeFailure ?? .noSuchPlace
        }
    }

    /// A sheet with a name field, unless `check` on a copy of the tree is refused (its reason is shown then,
    /// before any name is asked). `button` applies the edit `made` gives for the name; Cancel does nothing.
    private func askName(_ title: String, button: String, name: String, unless check: (inout Tree<Tab>) throws -> Void,
                         made: @escaping (String) -> (inout Tree<Tab>) throws -> Void) {
        var copy = tree
        if let failure = refusal({ try check(&copy) }) { return showRefusal(failure) }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "Name of the group"
        alert.addButton(withTitle: button)
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(string: name)
        field.frame = NSRect(x: 0, y: 0, width: 240, height: 24)
        AppFont.apply(to: [field])
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        ask(alert, for: nil) { [weak self] pressed in if pressed == 0 { self?.change(made(field.stringValue)) } }
    }
}
