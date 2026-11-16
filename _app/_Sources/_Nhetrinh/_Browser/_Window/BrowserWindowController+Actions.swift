import AppKit

/// Menu actions. They reach the window controller through the responder chain (see AppMenu).
extension BrowserWindowController {
    @objc func newTab(_ sender: Any?) {
        tabs.append(Tab(url: nil))
        select(tabs.count - 1)
        focusAddress(nil)
    }

    @objc func closeTab(_ sender: Any?) { close(at: selected) }
    @objc func focusAddress(_ sender: Any?) { window?.makeFirstResponder(toolbar.address) }
    @objc func reload(_ sender: Any?) { current?.reload() }
    @objc func goBack(_ sender: Any?) { current?.goBack() }
    @objc func goForward(_ sender: Any?) { current?.goForward() }

    /// ⌘1 to ⌘8 select that tab; ⌘9 selects the last tab.
    @objc func selectTabByNumber(_ sender: NSMenuItem) {
        select(sender.tag == 9 ? tabs.count - 1 : sender.tag - 1)
    }

    @objc func toggleTabSidebar(_ sender: Any?) {
        split.splitViewItems.first?.animator().isCollapsed.toggle()
    }
}
