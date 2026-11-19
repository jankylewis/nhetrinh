import AppKit

/// Menu actions. Their menu items target the window controller directly (see AppMenu, NT-UIX-001).
extension BrowserWindowController {
    @objc func newTab(_ sender: Any?) {
        tree.insert(Tab(url: nil), atFlat: tabs.count)  // the top level's end, never inside the last group
        select(tabs.count - 1)
        focusAddress(nil)
    }

    @objc func closeTab(_ sender: Any?) { close(at: selected) }

    /// Duplicate Tab (a row's menu): a copy right after the tab, in its group, with its page, title, icon and
    /// back / forward history (given at its first load, as a restored tab's); the copy is selected.
    func duplicate(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        let source = tabs[index]
        let copy = Tab(url: source.webView?.url ?? source.url, title: source.title)
        copy.icon = source.icon
        copy.savedState = source.webView?.interactionState ?? source.savedState
        tree.insert(copy, afterFlat: index)
        select(index + 1)
    }
    @objc func focusAddress(_ sender: Any?) { window?.makeFirstResponder(toolbar.address) }
    @objc func reload(_ sender: Any?) { current?.reload() }
    @objc func stopLoading(_ sender: Any?) { current?.stopLoading() }
    @objc func goBack(_ sender: Any?) { current?.goBack() }
    @objc func goForward(_ sender: Any?) { current?.goForward() }

    /// ⌘1 to ⌘8 select that tab; ⌘9 selects the last. They count the tabs a user sees: a tab under a
    /// collapsed group, at any level, is skipped (P7, P8-GROUPS-1).
    @objc func selectTabByNumber(_ sender: NSMenuItem) {
        let shown = tree.visibleFlatIndexes
        let number = sender.tag == 9 ? shown.count - 1 : sender.tag - 1
        if shown.indices.contains(number) { select(shown[number]) }
    }

    @objc func toggleTabSidebar(_ sender: Any?) {
        sideItem?.animator().isCollapsed.toggle()
        sessionChanged()
    }
}
