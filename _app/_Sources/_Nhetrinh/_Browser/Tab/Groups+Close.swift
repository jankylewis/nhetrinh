import AppKit
import NhetrinhCore

/// P8-GROUPS-1: Close Group… (a confirmation naming the tab count, then the group and every tab in it
/// close) and its reopen by File > Reopen Closed Tab: the group comes back whole, where it was. The probe's
/// group fields (R39 to R43, R49).
extension BrowserWindowController {
    func askToCloseGroup(at path: TabPath) {
        guard let group = try? tree.group(at: path) else { return showRefusal(.noSuchPlace) }
        let count = group.allTabs.count
        let alert = NSAlert()
        alert.messageText = "Close the group “\(group.name)” and its \(count == 1 ? "1 tab" : "\(count) tabs")?"
        alert.informativeText = "File > Reopen Closed Tab brings the group back."
        alert.addButton(withTitle: "Close")
        alert.addButton(withTitle: "Cancel")
        ask(alert, for: nil) { [weak self] pressed in if pressed == 0 { self?.closeGroup(at: path) } }
    }

    /// The group at `path` and every tab in it close; it is kept for Reopen Closed Tab. The selection moves
    /// to the nearest visible tab when it was inside; the window closes with its last tab, as ⌘W does.
    func closeGroup(at path: TabPath) {
        guard let group = try? tree.group(at: path) else { return }
        let chosen = tabs.indices.contains(selected) ? tabs[selected] : nil
        let inside = group.allTabs
        let first = inside.first.flatMap { tab in tabs.firstIndex { $0 === tab } } ?? 0
        let saved = Tree(items: group.items).compactMapTabs { tab in
            tab.url.map { SessionTab(url: $0, title: tab.title) }
        }
        closedTabs.push(.group(ClosedGroup(group: TabFolder(name: group.name, collapsed: group.collapsed,
                                                            items: saved.items),
                                           path: path, groups: tree.groupNames(along: path.parent))))
        for tab in inside {
            endSheets(of: tab.webView)  // S1
            tab.unload()
        }
        _ = try? tree.removeGroup(at: path)
        backgroundSlot = nil
        if tabs.isEmpty {
            window?.close()
            return
        }
        guard let chosen, !inside.contains(where: { $0 === chosen }) else {
            selected = -1
            return select(tree.nearestVisible(afterRemoving: first) ?? 0)
        }
        selected = tabs.firstIndex { $0 === chosen } ?? 0
        refreshChrome()
    }

    /// Reopen Closed Tab of a group: back where it was, the groups on its path made again when gone; its
    /// first tab is selected.
    func reopenGroup(_ closed: ClosedGroup) {
        let made = Tree(items: closed.group.items).compactMapTabs { Tab(url: $0.url, title: $0.title) }
        let group = TreeFolder(name: closed.group.name, collapsed: closed.group.collapsed, items: made.items)
        keepingSelection { tree.reinsert(.folder(group), at: closed.path, groups: closed.groups, recreate: true) }
        guard let first = made.allTabs.first, let index = tabs.firstIndex(where: { $0 === first }) else {
            return refreshChrome()
        }
        select(index)
    }

    /// The probe's group fields: every group top to bottom (its name, own tabs, collapsed state, path, tab
    /// count), each shown row's level, every tab's title, the last refusal's reason.
    func readGroups(into state: inout ProbeState) {
        for path in tree.groupPaths {
            guard let group = try? tree.group(at: path) else { continue }
            state.folders.append(group.name)
            state.folderTabs.append(group.items.compactMap { item in
                if case .tab(let tab) = item { return tab.title } else { return nil }
            })
            state.collapsedFolders.append(group.collapsed)
            state.groupPaths.append(tree.groupNames(along: path.indexes).joined(separator: " > "))
            state.groupCounts.append(group.allTabs.count)
        }
        state.rowLevels = sidebar.shownLevels
        state.tabTitles = tabs.map(\.title)
        state.groupRefusal = groupRefusal
    }
}
