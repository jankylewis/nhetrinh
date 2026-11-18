import AppKit
import NhetrinhCore

/// The readback probe's answers (D23). Only `AppDelegate` calls this, and only when the app was
/// started with `NHT_READBACK=1`. Each action takes the path the user's own action takes: a menu
/// item is performed as a click on it, an address is submitted as Return in the field, a row is
/// selected as a click in the sidebar. Nothing here sets the tabs directly.
extension BrowserWindowController {
    func probeAnswer(_ request: ProbeRequest, menu: NSMenu? = NSApp.mainMenu) -> ProbeResponse {
        switch request {
        case .state: return .state(probeState(menu: menu))
        case .navigate(let text):
            let field = toolbar.address
            field.stringValue = text
            let sent = field.sendAction(field.action, to: field.target)
            return sent ? .done : .failed("the address field did not submit")
        case .newTab: return Self.perform(["File", "New Tab"], in: menu)
        case .closeTab: return Self.perform(["File", "Close Tab"], in: menu)
        case .select(let row):
            return sidebar.selectAsClick(row) ? .done : .failed("the sidebar has no row \(row)")
        case .menu(let path): return Self.perform(path, in: menu, afterAnswer: true)
        case .rowMenu(let row, let item):
            return sidebar.pressRowMenu(row, item: item) ? .done : .failed("row \(row) has no menu item \(item)")
        case .linkMenu(let item): return showLinkMenu(pressing: item).map { .failed($0) } ?? .done
        case .button(let label):
            let pressed = toolbar.press(label) || findBar.press(label) || hub?.press(label) == true
            return pressed ? .done : .failed("no shown button \(label) in the toolbar, find bar or Settings Hub")
        case .click(let selector): return clickInPage(selector)
        case .sheetButton(let label): return pressSheetButton(label)
        case .sheetField(let index, let text): return typeInSheet(field: index, text)
        case .front: return comeToFront()
        case .find, .setting: return toolAnswer(request)
        case .middleClick(let row):
            return sidebar.middleClick(row) ? .done : .failed("the sidebar has no row \(row)")
        case .commandClickLink: return commandClickFirstLink().map { .failed($0) } ?? .done
        case .download(let row, let item): return pressDownload(row: row, item: item)
        }
    }

    func probeState(menu: NSMenu?) -> ProbeState {
        var state = ProbeState()
        state.title = window?.title ?? ""
        state.rows = sidebar.shownRows
        state.loaded = Array(tabs.map(\.isLoaded).prefix(state.rows.count))
        state.selected = sidebar.selectedRow >= 0 ? sidebar.selectedRow : nil
        state.address = toolbar.address.stringValue
        state.windowShown = window?.isVisible ?? false
        let sidebarShown = sidebar.window != nil && !sidebar.isHiddenOrHasHiddenAncestor
        state.sidebarWidth = sidebarShown ? Double(sidebar.frame.width) : 0
        state.addressShown = toolbar.address.window != nil && !toolbar.address.isHiddenOrHasHiddenAncestor
        state.shortcuts = menu.map { Self.shortcuts(in: $0, path: []) } ?? [:]
        state.icons = sidebar.shownIcons
        state.loading = current?.isLoading ?? false
        state.progressShown = toolbar.progressShown
        state.reloadButton = toolbar.reloadLabel
        state.webMenu = (current as? BrowserWebView)?.lastMenu ?? []
        readSheet(into: &state)
        readDownloads(into: &state)
        return state
    }

    /// Perform a menu item as a click does: its own action, sent to its own target. `afterAnswer`
    /// performs it on the next turn of the main queue, after the probe has sent `done`: an item that
    /// ends the app (nhetrinh > Quit nhetrinh) still answers.
    private static func perform(_ path: [String], in menu: NSMenu?, afterAnswer: Bool = false) -> ProbeResponse {
        var owner = menu
        for title in path.dropLast() { owner = owner?.item(withTitle: title)?.submenu }
        let index = owner?.indexOfItem(withTitle: path.last ?? "") ?? -1
        guard let owner, index >= 0 else { return .failed("no menu item \(path.joined(separator: " > "))") }
        if afterAnswer {
            DispatchQueue.main.async { owner.performActionForItem(at: index) }
        } else {
            owner.performActionForItem(at: index)
        }
        return .done
    }

    /// Every item with a shortcut, by its path: "File > New Tab" -> "⌘T".
    private static func shortcuts(in menu: NSMenu, path: [String]) -> [String: String] {
        var found: [String: String] = [:]
        for item in menu.items {
            let here = path + [item.title]
            if let submenu = item.submenu {
                found.merge(shortcuts(in: submenu, path: here)) { first, _ in first }
            } else if !item.keyEquivalent.isEmpty {
                found[here.joined(separator: " > ")] = Shortcut.text(key: item.keyEquivalent, keys: keys(item))
            }
        }
        return found
    }

    private static func keys(_ item: NSMenuItem) -> ShortcutKeys {
        let mask = item.keyEquivalentModifierMask
        let pairs: [(NSEvent.ModifierFlags, ShortcutKeys)] = [
            (.control, .control), (.option, .option), (.shift, .shift), (.command, .command),
        ]
        return pairs.reduce(into: ShortcutKeys()) { keys, pair in if mask.contains(pair.0) { keys.insert(pair.1) } }
    }
}
