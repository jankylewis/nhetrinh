import AppKit

/// The main menu. Every keyboard shortcut of the app is defined here, and nowhere else.
/// Browser items target the window controller directly: with no key window (the app not active,
/// as the readback starts it, D18) a nil target reaches nobody (NT-UIX-001).
/// Edit items keep a nil target: they act on the focused text, through the responder chain.
enum AppMenu {
    static func build(browser: BrowserWindowController) -> NSMenu {
        let main = NSMenu()
        [appMenu(), fileMenu(browser), editMenu(), viewMenu(browser), tabsMenu(browser)].forEach(main.addItem)
        return main
    }

    private static func appMenu() -> NSMenuItem {
        submenu("nhetrinh", [item("Quit nhetrinh", #selector(NSApplication.terminate(_:)), "q")])
    }

    private static func fileMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("File", [
            item("New Tab", #selector(BrowserWindowController.newTab(_:)), "t", browser),
            item("Reopen Closed Tab", #selector(BrowserWindowController.reopenClosedTab(_:)), "T", browser),
            item("Close Tab", #selector(BrowserWindowController.closeTab(_:)), "w", browser),
            item("Open Location", #selector(BrowserWindowController.focusAddress(_:)), "l", browser),
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

    private static func viewMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("View", [
            item("Toggle Sidebar", #selector(BrowserWindowController.toggleTabSidebar(_:)), "s", browser),
            item("Reload", #selector(BrowserWindowController.reload(_:)), "r", browser),
            item("Stop", #selector(BrowserWindowController.stopLoading(_:)), ".", browser),
        ])
    }

    private static func tabsMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        var items = [
            item("Back", #selector(BrowserWindowController.goBack(_:)), "[", browser),
            item("Forward", #selector(BrowserWindowController.goForward(_:)), "]", browser),
            NSMenuItem.separator(),
            item("Select Next Tab", #selector(BrowserWindowController.selectNextTab(_:)), "\t", browser, .control),
            item("Select Previous Tab", #selector(BrowserWindowController.selectPreviousTab(_:)), "\t", browser,
                 [.control, .shift]),
            item("Move Tab Up", #selector(BrowserWindowController.moveTabUp(_:)), "", browser),
            item("Move Tab Down", #selector(BrowserWindowController.moveTabDown(_:)), "", browser),
            NSMenuItem.separator(),
        ]
        for number in 1...9 {
            let select = #selector(BrowserWindowController.selectTabByNumber(_:))
            let entry = item("Tab \(number)", select, "\(number)", browser)
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

    private static func item(_ title: String, _ action: Selector, _ key: String, _ target: AnyObject? = nil,
                             _ keys: NSEvent.ModifierFlags = .command) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: key)
        entry.keyEquivalentModifierMask = keys
        entry.target = target
        return entry
    }
}
