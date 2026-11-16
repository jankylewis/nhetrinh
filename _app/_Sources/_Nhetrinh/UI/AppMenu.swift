import AppKit

/// The main menu. Every keyboard shortcut of the app is defined here, and nowhere else.
enum AppMenu {
    static func build() -> NSMenu {
        let main = NSMenu()
        [appMenu(), fileMenu(), editMenu(), viewMenu(), tabsMenu()].forEach(main.addItem)
        return main
    }

    private static func appMenu() -> NSMenuItem {
        submenu("nhetrinh", [item("Quit nhetrinh", #selector(NSApplication.terminate(_:)), "q")])
    }

    private static func fileMenu() -> NSMenuItem {
        submenu("File", [
            item("New Tab", #selector(BrowserWindowController.newTab(_:)), "t"),
            item("Close Tab", #selector(BrowserWindowController.closeTab(_:)), "w"),
            item("Open Location", #selector(BrowserWindowController.focusAddress(_:)), "l"),
        ])
    }

    private static func editMenu() -> NSMenuItem {
        submenu("Edit", [
            item("Undo", Selector(("undo:")), "z"),
            item("Redo", Selector(("redo:")), "Z"),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"),
            item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"),
            item("Select All", #selector(NSText.selectAll(_:)), "a"),
        ])
    }

    private static func viewMenu() -> NSMenuItem {
        submenu("View", [
            item("Toggle Sidebar", #selector(BrowserWindowController.toggleTabSidebar(_:)), "s"),
            item("Reload", #selector(BrowserWindowController.reload(_:)), "r"),
        ])
    }

    private static func tabsMenu() -> NSMenuItem {
        var items = [
            item("Back", #selector(BrowserWindowController.goBack(_:)), "["),
            item("Forward", #selector(BrowserWindowController.goForward(_:)), "]"),
            NSMenuItem.separator(),
        ]
        for number in 1...9 {
            let entry = item("Tab \(number)", #selector(BrowserWindowController.selectTabByNumber(_:)), "\(number)")
            entry.tag = number
            items.append(entry)
        }
        return submenu("Tabs", items)
    }

    private static func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenuItem {
        let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        items.forEach(menu.addItem)
        holder.submenu = menu
        return holder
    }

    private static func item(_ title: String, _ action: Selector, _ key: String) -> NSMenuItem {
        NSMenuItem(title: title, action: action, keyEquivalent: key)
    }
}
