import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var browser: BrowserWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = buildMenu()
        // Set the Dock icon at runtime: macOS puts bundle (.icns) icons on a tile,
        // a runtime image is drawn as-is (transparent, full size).
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        browser = BrowserWindowController()
        browser.showWindow(nil)
        browser.openInitialTabs()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Menu (shortcuts live here)

    private func buildMenu() -> NSMenu {
        let main = NSMenu()
        main.addItem(submenu("nhetrinh", [
            item("Quit nhetrinh", #selector(NSApplication.terminate(_:)), "q"),
        ]))
        main.addItem(submenu("File", [
            item("New Tab", #selector(BrowserWindowController.newTab(_:)), "t"),
            item("Close Tab", #selector(BrowserWindowController.closeTab(_:)), "w"),
            item("Open Location", #selector(BrowserWindowController.focusAddress(_:)), "l"),
        ]))
        main.addItem(submenu("Edit", [
            item("Undo", Selector(("undo:")), "z"),
            item("Redo", Selector(("redo:")), "Z"),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"),
            item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"),
            item("Select All", #selector(NSText.selectAll(_:)), "a"),
        ]))
        main.addItem(submenu("View", [
            item("Toggle Sidebar", #selector(BrowserWindowController.toggleTabSidebar(_:)), "s"),
            item("Reload", #selector(BrowserWindowController.reload(_:)), "r"),
        ]))
        var tabItems: [NSMenuItem] = [
            item("Back", #selector(BrowserWindowController.goBack(_:)), "["),
            item("Forward", #selector(BrowserWindowController.goForward(_:)), "]"),
            .separator(),
        ]
        for n in 1...9 {
            let it = item("Tab \(n)", #selector(BrowserWindowController.selectTabByNumber(_:)), "\(n)")
            it.tag = n
            tabItems.append(it)
        }
        main.addItem(submenu("Tabs", tabItems))
        return main
    }

    private func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach { menu.addItem($0) }
        holder.submenu = menu
        return holder
    }

    private func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: key)
    }
}
