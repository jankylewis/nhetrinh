import Foundation

/// What the app shows, as the readback needs it (R1, R3-R7, R9-R26). Every field has a default, so an
/// answer from an older app still decodes; the readback then sees the default and says so.
public struct ProbeState: Equatable, Sendable {
    public var title = ""
    /// The sidebar rows, top to bottom, as the table shows them.
    public var rows: [String] = []
    /// Per row: whether its tab is loaded (a dimmed row is not).
    public var loaded: [Bool] = []
    /// The selected sidebar row; nil when none is selected.
    public var selected: Int?
    /// The text in the address field.
    public var address = ""
    public var windowShown = false
    public var sidebarWidth = 0.0
    public var addressShown = false
    /// Menu item path ("File > New Tab") to its shortcut as the menu shows it ("⌘T").
    public var shortcuts: [String: String] = [:]
    /// Per row: whether it shows its site's icon (P2).
    public var icons: [Bool] = []
    /// Whether the selected tab's page is loading (P2).
    public var loading = false
    /// The toolbar's reload button as its label reads: "Reload", or "Stop" while a page loads (P2).
    public var reloadButton = ""
    /// The items of the page's last context menu, as it was shown (P2).
    public var webMenu: [String] = []
    /// The window's sheet (P3): its text ("" when none), its kind ("alert", "open", "print"; "" none),
    /// its buttons, and how many sheets were shown since launch (a sheet asked again counts again).
    public var sheet = ""
    public var sheetKind = ""
    public var sheetButtons: [String] = []
    public var sheetsShown = 0
    /// How many links were handed to another app through macOS since launch (P3).
    public var handedOff = 0
    /// Whether a window of the app is in fullscreen (P3, R26b).
    public var fullscreen = false
    /// Whether the app is the active app, with the focus (D25: R26a, R26b say whether they took it).
    public var active = false

    public init() {}
}

extension ProbeState {
    var object: [String: Any] {
        var object: [String: Any] = ["title": title, "rows": rows, "loaded": loaded, "address": address,
                                     "windowShown": windowShown, "sidebarWidth": sidebarWidth,
                                     "addressShown": addressShown, "shortcuts": shortcuts, "icons": icons,
                                     "loading": loading, "reloadButton": reloadButton, "webMenu": webMenu,
                                     "sheet": sheet, "sheetKind": sheetKind, "sheetButtons": sheetButtons,
                                     "sheetsShown": sheetsShown, "handedOff": handedOff, "fullscreen": fullscreen,
                                     "active": active]
        if let selected { object["selected"] = selected }
        return object
    }

    /// A field that is missing or of another type keeps its default: the readback then sees it.
    init(_ object: [String: Any]) {
        title = object["title"] as? String ?? ""
        rows = object["rows"] as? [String] ?? []
        loaded = object["loaded"] as? [Bool] ?? []
        selected = object["selected"] as? Int
        address = object["address"] as? String ?? ""
        windowShown = object["windowShown"] as? Bool ?? false
        sidebarWidth = object["sidebarWidth"] as? Double ?? 0
        addressShown = object["addressShown"] as? Bool ?? false
        shortcuts = object["shortcuts"] as? [String: String] ?? [:]
        icons = object["icons"] as? [Bool] ?? []
        loading = object["loading"] as? Bool ?? false
        reloadButton = object["reloadButton"] as? String ?? ""
        webMenu = object["webMenu"] as? [String] ?? []
        sheet = object["sheet"] as? String ?? ""
        sheetKind = object["sheetKind"] as? String ?? ""
        sheetButtons = object["sheetButtons"] as? [String] ?? []
        sheetsShown = object["sheetsShown"] as? Int ?? 0
        handedOff = object["handedOff"] as? Int ?? 0
        fullscreen = object["fullscreen"] as? Bool ?? false
        active = object["active"] as? Bool ?? false
    }
}
