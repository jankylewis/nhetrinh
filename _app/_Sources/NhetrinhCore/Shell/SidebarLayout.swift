import Foundation

/// P8-SIDE-1 (headmate request): the side of the window the tab sidebar sits on, chosen in the Settings Hub
/// (Sidebar position) and kept in `prefs.json`. Left unless Right is saved.
public enum SidebarSide: String, CaseIterable, Sendable {
    case left, right

    public var title: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    /// The toolbar's Toggle Sidebar symbol: the sidebar drawn on this side.
    public var symbol: String { "sidebar." + rawValue }
}

/// Where the sidebar and the main area (toolbar over web view) sit in a window, in its points from the left.
/// The traffic lights stay top left: they sit over the sidebar only when it is shown on the left; else over
/// the toolbar, whose first button then starts right of them (`ToolbarLayout.leading`, P8-CHROME-1).
public enum SidebarLayout {
    public struct Place: Equatable, Sendable {
        /// The toolbar's (and the web view's) left edge.
        public let toolbarX: Double
        /// The sidebar's left edge; nil when it is hidden.
        public let sidebarX: Double?

        public init(toolbarX: Double, sidebarX: Double?) {
            self.toolbarX = toolbarX
            self.sidebarX = sidebarX
        }
    }

    /// A window `width` wide, a sidebar `sidebarWidth` wide, a divider `divider` thick between them.
    public static func place(_ side: SidebarSide, shown: Bool, width: Double, sidebarWidth: Double,
                             divider: Double) -> Place {
        guard shown else { return Place(toolbarX: 0, sidebarX: nil) }
        switch side {
        case .left: return Place(toolbarX: sidebarWidth + divider, sidebarX: 0)
        case .right: return Place(toolbarX: 0, sidebarX: width - sidebarWidth)
        }
    }

    /// Whether the sidebar sits under the traffic lights; when not, the toolbar does and takes the inset.
    public static func underLights(_ side: SidebarSide, shown: Bool) -> Bool { side == .left && shown }

    /// The split view's divider position that keeps the sidebar `sidebarWidth` wide in a window `width` wide.
    public static func divider(_ side: SidebarSide, sidebarWidth: Double, width: Double, thickness: Double) -> Double {
        side == .left ? sidebarWidth : width - sidebarWidth - thickness
    }

    /// Whether two frames ([x, y, width, height]) share a part of their x range. A frame not read (not 4
    /// numbers) counts as an overlap: never taken as clear.
    public static func overlap(_ one: [Double], _ other: [Double]) -> Bool {
        guard one.count == 4, other.count == 4 else { return true }
        return one[0] < other[0] + other[2] && other[0] < one[0] + one[2]
    }
}
