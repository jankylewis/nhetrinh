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
    /// Per row: whether its row view shows its site's icon, not the globe (P2).
    public var icons: [Bool] = []
    /// Whether the selected tab's page is loading (P2).
    public var loading = false
    /// Whether the progress line under the toolbar is shown (P2).
    public var progressShown = false
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
    /// P4: the find bar shown and its last answer ("found", "not found"; "" none), the zoom badge
    /// ("" at 100 %), the window's look ("dark", "light"), whether the Settings Hub window is shown.
    public var findShown = false
    public var findResult = ""
    public var zoomBadge = ""
    public var appearance = ""
    public var hubShown = false
    /// P5: the sidebar footer's download rows, top to bottom: names and second lines ("42 %", "done",
    /// "failed: …", "cancelled"), and the files Finder was asked to show, by name.
    public var downloads: [String] = []
    public var downloadStates: [String] = []
    public var revealed: [String] = []
    /// P7: every group, top to bottom (a group's groups after it): its name, its own tabs' titles, whether
    /// it is collapsed. P8-GROUPS-1: its path ("MBing > FE"), its tab count at any depth; per shown row its
    /// level (0: the top); every tab's title, hidden ones too; the reason of the last refusal shown.
    public var folders: [String] = []
    public var folderTabs: [[String]] = []
    public var collapsedFolders: [Bool] = []
    public var groupPaths: [String] = []
    public var groupCounts: [Int] = []
    public var rowLevels: [Int] = []
    public var tabTitles: [String] = []
    public var groupRefusal = ""
    /// P8-MIN-1: whether the browser window is minimized to the Dock.
    public var minimized = false
    /// P8-FONT-1: per main control ("address bar", "sidebar row", …) the font family it shows; "mixed: …"
    /// when its parts differ. A control that is not there (no group row, no Settings Hub yet) is missing.
    public var fonts: [String: String] = [:]
    /// P8-CHROME-1: the toolbar's left buttons ("Toggle Sidebar", "Back") as [x, y, width, height] in the
    /// window's points, and the zoom button's right edge in the same points; nil when it was not read.
    public var toolbarFrames: [String: [Double]] = [:]
    public var zoomMaxX: Double?
    /// P8-SIDE-1: the sidebar's side ("left", "right"; "" not read), the toolbar toggle's symbol, the sidebar's
    /// frame ([] when hidden) and the web view's frame, as [x, y, width, height] in the window's points.
    public var sidebarSide = ""
    public var toggleSymbol = ""
    public var sidebarFrame: [Double] = []
    public var webFrame: [Double] = []

    public init() {}
}

extension ProbeState {
    var object: [String: Any] {
        var object: [String: Any] = ["title": title, "rows": rows, "loaded": loaded, "address": address,
                                     "windowShown": windowShown, "sidebarWidth": sidebarWidth,
                                     "addressShown": addressShown, "shortcuts": shortcuts, "icons": icons,
                                     "loading": loading, "progressShown": progressShown, "reloadButton": reloadButton,
                                     "webMenu": webMenu, "sheet": sheet, "sheetKind": sheetKind,
                                     "sheetButtons": sheetButtons, "sheetsShown": sheetsShown, "handedOff": handedOff,
                                     "fullscreen": fullscreen, "active": active, "findShown": findShown,
                                     "findResult": findResult, "zoomBadge": zoomBadge, "appearance": appearance,
                                     "hubShown": hubShown, "downloads": downloads,
                                     "downloadStates": downloadStates, "revealed": revealed,
                                     "minimized": minimized, "fonts": fonts, "toolbarFrames": toolbarFrames]
        if let selected { object["selected"] = selected }
        if let zoomMaxX { object["zoomMaxX"] = zoomMaxX }
        return object.merging(groupObject) { first, _ in first }.merging(sideObject) { first, _ in first }
    }

    /// A field that is missing or of another type keeps its default: the readback then sees it.
    init(_ object: [String: Any]) {
        title = object["title"] as? String ?? ""
        rows = object["rows"] as? [String] ?? []
        loaded = object["loaded"] as? [Bool] ?? []
        selected = object["selected"] as? Int
        address = object["address"] as? String ?? ""
        readWindow(object)
        shortcuts = object["shortcuts"] as? [String: String] ?? [:]
        icons = object["icons"] as? [Bool] ?? []
        loading = object["loading"] as? Bool ?? false
        progressShown = object["progressShown"] as? Bool ?? false
        reloadButton = object["reloadButton"] as? String ?? ""
        webMenu = object["webMenu"] as? [String] ?? []
        sheet = object["sheet"] as? String ?? ""
        sheetKind = object["sheetKind"] as? String ?? ""
        sheetButtons = object["sheetButtons"] as? [String] ?? []
        sheetsShown = object["sheetsShown"] as? Int ?? 0
        handedOff = object["handedOff"] as? Int ?? 0
        fullscreen = object["fullscreen"] as? Bool ?? false
        active = object["active"] as? Bool ?? false
        findShown = object["findShown"] as? Bool ?? false
        findResult = object["findResult"] as? String ?? ""
        zoomBadge = object["zoomBadge"] as? String ?? ""
        appearance = object["appearance"] as? String ?? ""
        hubShown = object["hubShown"] as? Bool ?? false
        readDownloads(object)
        readGroups(object)
        readSide(object)
    }

    private mutating func readWindow(_ object: [String: Any]) {
        windowShown = object["windowShown"] as? Bool ?? false
        minimized = object["minimized"] as? Bool ?? false
        fonts = object["fonts"] as? [String: String] ?? [:]
        toolbarFrames = object["toolbarFrames"] as? [String: [Double]] ?? [:]
        zoomMaxX = object["zoomMaxX"] as? Double
        sidebarWidth = object["sidebarWidth"] as? Double ?? 0
        addressShown = object["addressShown"] as? Bool ?? false
    }

    private mutating func readDownloads(_ object: [String: Any]) {
        downloads = object["downloads"] as? [String] ?? []
        downloadStates = object["downloadStates"] as? [String] ?? []
        revealed = object["revealed"] as? [String] ?? []
    }
}
