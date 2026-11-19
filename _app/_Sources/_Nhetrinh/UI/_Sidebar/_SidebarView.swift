import AppKit
import NhetrinhCore

/// The vertical tab list, an outline (P7): tabs and groups, a group's items under it, indented by level
/// (P8-GROUPS-1). One row per tab (`TabRowView`): icon, title, close button on hover; a tab that is not
/// loaded is dimmed. A row's menu and a middle click close it (P2); a drag moves a tab or a group
/// (`+Outline`); the groups' menus: `+Groups`. A double click on a group's row renames it.
final class SidebarView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    struct Row {
        let title: String
        let loaded: Bool
        let icon: NSImage?
    }

    static let rowType = NSPasteboard.PasteboardType("nhetrinh.tab-row")

    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onDuplicate: ((Int) -> Void)?
    var onNewTab: (() -> Void)?
    /// A group action or a drop (P7).
    var onAction: ((SidebarAction) -> Void)?
    /// Why the item at a path cannot move into the group at a path at an index (nil: it can): the
    /// controller's tree answers; a drop and a menu item check it first (P8-GROUPS-1).
    var moveRefusal: ((TabPath, [Int], Int?) -> TreeFailure?)?

    let table = TabTable()
    /// P5: the footer's download rows (`../Bars/DownloadsBar.swift`), below the tabs.
    let downloads = DownloadsBar()
    /// True while `update` sets the outline: its own expand and select calls are not the user's.
    var updating = false
    /// How many times the whole outline was reloaded (R-11: only when the tree's shape changed).
    var reloads = 0
    private lazy var newTab = makeNewTabButton()

    override init(frame: NSRect) {
        super.init(frame: frame)
        configureTable()
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        layOut(newTab: newTab, scroll: scroll)
    }

    required init?(coder: NSCoder) { return nil }

    /// The outline's root nodes, made new at every update (P7).
    var nodes: [SidebarNode] = []

    private func configureTable() {
        let column = NSTableColumn(identifier: .init("tab"))
        table.addTableColumn(column)
        table.outlineTableColumn = column
        table.indentationPerLevel = 10
        table.headerView = nil
        table.style = .sourceList
        table.rowHeight = 28
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityIdentifier("nhetrinh.sidebar")
        table.registerForDraggedTypes([Self.rowType])
        table.setDraggingSourceOperationMask(.move, forLocal: true)
        table.onMiddleClick = { [weak self] row in self?.closeRow(row) }
        table.menuForRow = { [weak self] row in self?.menu(forRow: row) }
        table.target = self
        table.doubleAction = #selector(doubleClicked)
    }

    private func makeNewTabButton() -> NSButton {
        let button = NSButton(title: "+  New Tab", target: self, action: #selector(newClicked))
        button.isBordered = false
        button.alignment = .left
        button.contentTintColor = .secondaryLabelColor
        button.setAccessibilityIdentifier("nhetrinh.newTab")
        AppFont.apply(to: [button])
        return button
    }

    private func layOut(newTab: NSButton, scroll: NSScrollView) {
        for view in [newTab, scroll, downloads] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            newTab.topAnchor.constraint(equalTo: topAnchor, constant: 44),  // below the window buttons
            newTab.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            newTab.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scroll.topAnchor.constraint(equalTo: newTab.bottomAnchor, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: downloads.topAnchor),
            downloads.leadingAnchor.constraint(equalTo: leadingAnchor),
            downloads.trailingAnchor.constraint(equalTo: trailingAnchor),
            downloads.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// The rows as the outline shows them (a group row reads its name), and per row whether its tab is
    /// loaded (a group: no) and its level; the selected row (-1: none). Read by the probe (D23).
    var shownRows: [String] { shownNodes.map(\.row.title) }
    var shownLoaded: [Bool] { shownNodes.map(\.row.loaded) }
    var shownLevels: [Int] { shownNodes.map(\.level) }
    var selectedRow: Int { table.selectedRow }

    private var shownNodes: [SidebarNode] { (0..<table.numberOfRows).compactMap(node(atRow:)) }

    func node(atRow row: Int) -> SidebarNode? { table.item(atRow: row) as? SidebarNode }

    func tabNode(flat: Int) -> SidebarNode? { SidebarNode.all(nodes).first { $0.flat == flat } }

    /// Select a tab's row as a click does: the outline reports the change, and `onSelect` shows that tab.
    /// A group's row is not selected by a click.
    func selectAsClick(_ row: Int) -> Bool {
        guard node(atRow: row)?.isGroup == false else { return false }
        table.selectRowIndexes([row], byExtendingSelection: false)
        return true
    }

    func closeRow(_ row: Int) {
        if let flat = node(atRow: row)?.flat { onClose?(flat) }
    }

    /// The New Tab button's text (P8-FONT-1): the controls above the rows.
    var textControls: [NSControl] { [newTab] }

    @objc private func newClicked() { onNewTab?() }

    @objc private func doubleClicked() { doubleClick(row: table.clickedRow) }

    /// A double click on a group's row: Rename Group… (P8-GROUPS-1); on a tab's row, nothing more.
    func doubleClick(row: Int) {
        guard let node = node(atRow: row), node.isGroup else { return }
        onAction?(.rename(node.path))
    }
}
