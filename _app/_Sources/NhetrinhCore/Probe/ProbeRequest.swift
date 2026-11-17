import Foundation

/// A readback probe request (D23). One JSON object per line, one request per connection.
public enum ProbeRequest: Equatable, Sendable {
    case state
    case navigate(String)
    case newTab
    case closeTab
    case select(Int)
    /// A menu item by its path, ["Tabs", "Back"], performed as a click on it once the answer is sent.
    case menu([String])
    /// A sidebar row's menu, shown on that row, and its item `item` pressed (R13).
    case rowMenu(row: Int, item: String)
    /// The context menu of the first link in the selected page, and its item `item` pressed (R17).
    case linkMenu(item: String)
    /// A toolbar button by its label ("Stop"), pressed (R18).
    case button(String)
    /// A left click on the first element the CSS selector finds in the selected page (P3).
    case click(String)
    /// The window's sheet: press its button `label` (P3: a page dialog, the open or print panel).
    case sheetButton(String)
    /// The window's sheet: type `text` into its text field `index` (0 first), as a user replaces it (P3).
    case sheetField(index: Int, text: String)
    /// Bring nhetrinh to the front and take the focus: only R26a and R26b, only with `--allow-focus` (D25).
    case front
    /// Simulate macOS memory pressure at this level (P6). Readback only: the probe exists only with
    /// NHT_READBACK=1; real system pressure is never made.
    case pressure(UnloadPolicy.Pressure)
    /// The find bar's field: `text` typed, then Return, as a user searches (P4, R27).
    case find(String)
    /// The Settings Hub's control `name` set to `value` as a user picks it ("Search engine", "DuckDuckGo") (P4).
    case setting(name: String, value: String)
    /// A middle click on a sidebar row (R13).
    case middleClick(row: Int)
    /// A ⌘-click on the first link in the selected page (R17).
    case commandClickLink
    /// The download row `row` (0 top) in the sidebar footer: "Cancel" pressed, or the row clicked
    /// ("Show in Finder") (P5).
    case download(row: Int, item: String)
    /// The browser window: "Minimize" is Window > Minimize performed on it; "Restore" (P8-MIN-1).
    case window(String)
}

public enum ProbeResponse: Equatable, Sendable {
    case state(ProbeState)
    case done
    case failed(String)
}
