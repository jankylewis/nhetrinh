import AppKit
import NhetrinhCore

/// P7 tab folders (hubs/product/plan/M3_V1_RELEASE.md). The tree (`tree`) is the tabs' order; every
/// operation is `Tree`'s (NhetrinhCore, unit tested). A folder's name is asked in a sheet on the window.
extension BrowserWindowController {
    /// The sidebar's items: root tabs and folders. A collapsed folder that holds the selected tab is marked.
    var sidebarItems: [SidebarItem] {
        let chosen = tabs.indices.contains(selected) ? tabs[selected] : nil
        func row(_ tab: Tab) -> SidebarView.Row {
            SidebarView.Row(title: tab.title, loaded: tab.isLoaded, icon: tab.icon)
        }
        return tree.items.map { item in
            switch item {
            case .tab(let tab): return .tab(row(tab))
            case .folder(let folder):
                let holds = folder.tabs.contains { $0 === chosen }
                return .folder(name: folder.name, collapsed: folder.collapsed, marked: folder.collapsed && holds,
                               tabs: folder.tabs.map(row))
            }
        }
    }

    /// Change the tabs' order; the selection stays on its tab, wherever the tab goes.
    func keepingSelection(_ change: () -> Void) {
        let chosen = tabs.indices.contains(selected) ? tabs[selected] : nil
        change()
        if let chosen, let index = tabs.firstIndex(where: { $0 === chosen }) { selected = index }
    }

    func sidebarAction(_ action: SidebarAction) {
        switch action {
        case .newFolder(let index):
            askFolderName("New Folder", button: "Create", name: "") { [weak self] name in
                self?.change { try $0.addFolder(named: name, at: index) }
            }
        case .rename(let index):
            let name = (try? tree.folder(at: index).name) ?? ""
            askFolderName("Rename Folder", button: "Rename", name: name) { [weak self] name in
                self?.change { try $0.rename(folder: index, to: name) }
            }
        case .setCollapsed(let index, let collapsed): change { try $0.setCollapsed(collapsed, folder: index) }
        case .delete(let index): change { try $0.deleteFolder(at: index) }
        case .drop(let from, let folder, let index):
            change { tree in
                let to = tree.destination(of: from, folder: folder, index: index)
                try tree.move(from: from, to: to)
            }
        }
    }

    /// Apply `body` to the tree, or nothing when the tree refuses (the sidebar is shown as it was).
    private func change(_ body: (inout Tree<Tab>) throws -> Void) {
        var next = tree
        do {
            try body(&next)
        } catch {
            Log.app.info("folders: refused (\(String(describing: error), privacy: .public))")
            return refreshChrome()
        }
        keepingSelection { tree = next }
        backgroundSlot = nil
        refreshChrome()
    }

    /// A sheet with a name field: `done` gets the name when `button` is pressed; Cancel does nothing.
    private func askFolderName(_ title: String, button: String, name: String, done: @escaping (String) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = "Name of the folder"
        alert.addButton(withTitle: button)
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(string: name)
        field.frame = NSRect(x: 0, y: 0, width: 240, height: 24)
        AppFont.apply(to: [field])
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        ask(alert, for: nil) { pressed in if pressed == 0 { done(field.stringValue) } }
    }

    /// The probe's P7 fields: every folder's name, tabs and collapsed state, root first.
    func readFolders(into state: inout ProbeState) {
        for item in tree.items {
            guard case .folder(let folder) = item else { continue }
            state.folders.append(folder.name)
            state.folderTabs.append(folder.tabs.map(\.title))
            state.collapsedFolders.append(folder.collapsed)
        }
    }
}
