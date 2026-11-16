import AppKit
import NhetrinhCore

/// P2 tab handling (hubs/product/plan/M1_DAILY_DRIVER.md): reorder, next and previous tab, reopen a
/// closed tab, a link in a background tab. The menu items target the window controller (AppMenu).
extension BrowserWindowController: NSMenuItemValidation {
    /// A dragged row and Tabs > Move Tab Up / Down: the selection follows its tab.
    func moveTab(from: Int, to: Int) {
        guard tabs.indices.contains(from), tabs.indices.contains(to), from != to else { return }
        let follows = TabOrder.index(selected, afterMoveFrom: from, to: to, count: tabs.count)
        tabs = TabOrder.move(tabs, from: from, to: to)
        selected = follows
        backgroundSlot = nil
        refreshChrome()
    }

    @objc func moveTabUp(_ sender: Any?) { moveTab(from: selected, to: selected - 1) }
    @objc func moveTabDown(_ sender: Any?) { moveTab(from: selected, to: selected + 1) }

    /// ⌃⇥ and ⌃⇧⇥: the next and the previous tab, round the end.
    @objc func selectNextTab(_ sender: Any?) { selectTab(by: 1) }
    @objc func selectPreviousTab(_ sender: Any?) { selectTab(by: -1) }

    private func selectTab(by step: Int) {
        guard !tabs.isEmpty else { return }
        select(((selected + step) % tabs.count + tabs.count) % tabs.count)
    }

    /// File > Reopen Closed Tab: the tab closed last comes back where it was, selected and loaded.
    @objc func reopenClosedTab(_ sender: Any?) {
        guard let closed = closedTabs.pop() else { return }
        let index = min(max(0, closed.index), tabs.count)
        if index <= selected { selected += 1 }
        tabs.insert(Tab(url: closed.url, title: closed.title), at: index)
        select(index)
    }

    /// A link for a background tab: after the selected tab (and after the ones opened from it since),
    /// not loaded until it is selected. The selected tab does not change.
    func openInBackground(_ url: URL) {
        let index = min(backgroundSlot ?? selected + 1, tabs.count)
        tabs.insert(Tab(url: url, title: url.host ?? url.absoluteString), at: index)
        backgroundSlot = index + 1
        refreshChrome()
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(reopenClosedTab(_:)): return closedTabs.count > 0
        case #selector(moveTabUp(_:)): return selected > 0
        case #selector(moveTabDown(_:)): return selected >= 0 && selected < tabs.count - 1
        case #selector(selectNextTab(_:)), #selector(selectPreviousTab(_:)): return tabs.count > 1
        case #selector(stopLoading(_:)): return current?.isLoading ?? false
        default: return true
        }
    }
}
