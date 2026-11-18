import AppKit
import NhetrinhCore

/// P2 tab handling (hubs/product/plan/M1_DAILY_DRIVER.md): reorder, next and previous tab, reopen a
/// closed tab, a link in a background tab. The menu items target the window controller (AppMenu).
extension BrowserWindowController: NSMenuItemValidation {
    /// Tabs > Move Tab Up / Down: one row within its container; at a folder's edge the tab steps out to
    /// the root; a root tab never enters a folder (P7-FIX-1, P4: `Tree.step`). The selection follows its
    /// tab. A drag and Move to Folder are `Folders.swift`'s.
    func moveSelectedTab(up: Bool) {
        guard let path = tree.path(ofFlat: selected) else { return }
        keepingSelection { tree.step(path, up: up) }
        backgroundSlot = nil
        refreshChrome()
    }

    /// Whether Move Tab Up / Down would move the selected tab.
    func canMoveSelectedTab(up: Bool) -> Bool {
        var copy = tree
        return tree.path(ofFlat: selected).flatMap { copy.step($0, up: up) } != nil
    }

    @objc func moveTabUp(_ sender: Any?) { moveSelectedTab(up: true) }
    @objc func moveTabDown(_ sender: Any?) { moveSelectedTab(up: false) }

    /// ⌃⇥ and ⌃⇧⇥: the next and the previous visible tab, round the end; the tabs of a collapsed folder
    /// are skipped (ruling after P7-FIX-1, `Tree.visibleStep`).
    @objc func selectNextTab(_ sender: Any?) { selectTab(by: 1) }
    @objc func selectPreviousTab(_ sender: Any?) { selectTab(by: -1) }

    private func selectTab(by step: Int) {
        if let next = tree.visibleStep(from: selected, by: step), next != selected { select(next) }
    }

    /// File > Reopen Closed Tab: the tab closed last comes back where it was, selected and loaded.
    @objc func reopenClosedTab(_ sender: Any?) {
        guard let closed = closedTabs.pop() else { return }
        let tab = Tab(url: closed.url, title: closed.title)
        keepingSelection {  // where it was in the tree (P7-FIX-1, P1); a tab closed before P7: by flat index
            guard let path = closed.path else { return tree.insert(tab, atFlat: min(max(0, closed.index), tabs.count)) }
            tree.reinsert(tab, at: path, folder: closed.folder)
        }
        select(tabs.firstIndex { $0 === tab } ?? 0)
    }

    /// A link for a background tab: after the selected tab (and after the ones opened from it since),
    /// not loaded until it is selected. The selected tab does not change.
    func openInBackground(_ url: URL) {
        guard Self.opensInBackground(url) else { return }
        let index = min(backgroundSlot ?? selected + 1, tabs.count)
        keepingSelection { tree.insert(Tab(url: url, title: url.host ?? url.absoluteString), atFlat: index) }
        backgroundSlot = index + 1
        refreshChrome()
    }

    /// A `javascript:` link runs in its own page, never in a new tab: no tab is made, none is saved.
    static func opensInBackground(_ url: URL) -> Bool { url.scheme?.lowercased() != "javascript" }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(reopenClosedTab(_:)): return closedTabs.count > 0
        case #selector(moveTabUp(_:)): return canMoveSelectedTab(up: true)
        case #selector(moveTabDown(_:)): return canMoveSelectedTab(up: false)
        case #selector(selectNextTab(_:)), #selector(selectPreviousTab(_:)):
            return tree.visibleStep(from: selected, by: 1).map { $0 != selected } ?? false
        case #selector(stopLoading(_:)): return current?.isLoading ?? false
        default: return true
        }
    }
}
