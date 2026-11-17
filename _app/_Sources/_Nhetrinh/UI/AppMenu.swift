import AppKit

/// The main menu. Every keyboard shortcut of the app is defined here, and nowhere else.
/// Browser items target the window controller directly: with no key window (the app not active,
/// as the readback starts it, D18) a nil target reaches nobody (NT-UIX-001).
/// Edit and Window items keep a nil target: they act on the focused text or the key window.
enum AppMenu {
    /// The main menu, and its Window menu as the app's: macOS adds the window list to it (P8-MIN-1).
    static func install(browser: BrowserWindowController) {
        let main = build(browser: browser)
        NSApp.mainMenu = main
        NSApp.windowsMenu = main.item(withTitle: "Window")?.submenu
    }

    static func build(browser: BrowserWindowController) -> NSMenu {
        let main = NSMenu()
        [appMenu(browser), fileMenu(browser), editMenu(browser), viewMenu(browser), tabsMenu(browser), windowMenu()]
            .forEach(main.addItem)
        return main
    }

    private static func appMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("nhetrinh", [
            item("Settings Hub…", #selector(BrowserWindowController.showSettingsHub(_:)), ",", browser),
            .separator(),
            item("Quit nhetrinh", #selector(NSApplication.terminate(_:)), "q"),
        ])
    }

    private static func fileMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("File", [
            item("New Tab", #selector(BrowserWindowController.newTab(_:)), "t", browser),
            item("Reopen Closed Tab", #selector(BrowserWindowController.reopenClosedTab(_:)), "T", browser),
            item("Close Tab", #selector(BrowserWindowController.closeTab(_:)), "w", browser),
            item("Open Location", #selector(BrowserWindowController.focusAddress(_:)), "l", browser),
            .separator(),
            item("Print…", #selector(BrowserWindowController.printPage(_:)), "p", browser),
        ])
    }

    /// Find targets the browser (the bar is the browser's); the text items keep a nil target.
    private static func editMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("Edit", [
            item("Undo", Selector(("undo:")), "z"),
            item("Redo", Selector(("redo:")), "Z"),
            .separator(),
            item("Cut", #selector(NSText.cut(_:)), "x"),
            item("Copy", #selector(NSText.copy(_:)), "c"),
            item("Paste", #selector(NSText.paste(_:)), "v"),
            item("Select All", #selector(NSText.selectAll(_:)), "a"),
            .separator(),
            submenu("Find", [
                item("Find…", #selector(BrowserWindowController.showFind(_:)), "f", browser),
                item("Find Next", #selector(BrowserWindowController.findNext(_:)), "g", browser),
                item("Find Previous", #selector(BrowserWindowController.findPrevious(_:)), "G", browser),
            ]),
        ])
    }

    private static func viewMenu(_ browser: BrowserWindowController) -> NSMenuItem {
        submenu("View", [
            item("Toggle Sidebar", #selector(BrowserWindowController.toggleTabSidebar(_:)), "s", browser),
            item("Reload", #selector(BrowserWindowController.reload(_:)), "r", browser),
            item("Stop", #selector(BrowserWindowController.stopLoading(_:)), ".", browser),
            .separator(),
            item("Zoom In", #selector(BrowserWindowController.zoomIn(_:)), "+", browser),
            zoomInWithoutShift(browser),
            item("Zoom Out", #selector(BrowserWindowController.zoomOut(_:)), "-", browser),
            item("Actual Size", #selector(BrowserWindowController.actualSize(_:)), "0", browser),
        ])
    }

    /// ⌘= zooms in too: on most keyboards + needs Shift (F9). Hidden, its key still answers.
    private static func zoomInWithoutShift(_ browser: BrowserWindowController) -> NSMenuItem {
        let entry = item("Zoom In", #selector(BrowserWindowController.zoomIn(_:)), "=", browser)
        entry.isHidden = true
        entry.allowsKeyEquivalentWhenHidden = true
        return entry
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

    /// ⌘M minimizes the key window (P8-MIN-1); Zoom has no key, as in every Mac app.
    private static func windowMenu() -> NSMenuItem {
        submenu("Window", [
            item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m"),
            item("Zoom", #selector(NSWindow.performZoom(_:)), ""),
        ])
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
