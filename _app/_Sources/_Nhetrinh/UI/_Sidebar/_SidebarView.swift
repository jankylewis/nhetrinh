import AppKit
import NhetrinhCore

/// The vertical tab list, an outline (P7): root tabs and folders, a folder's tabs under it. One row per tab
/// (`TabRowView`): icon, title, close button on hover; a tab that is not loaded is dimmed. A row's menu
/// and a middle click close it (P2); a drag moves a tab or a folder (`+Drag`); folders: `+Folders`.
final class SidebarView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    struct Row {
        let title: String
        let loaded: Bool
        let icon: NSImage?
    }

    static let rowType = NSPasteboard.PasteboardType("nhetrinh.tab-row")

    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onNewTab: (() -> Void)?
    /// A folder action or a drop (P7).
    var onAction: ((SidebarAction) -> Void)?

    let table = TabTable()
    private var rows: [Row] = []
    private(set) var updating = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        configureTable()
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        layOut(newTab: makeNewTabButton(), scroll: scroll)
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
    }

    private func makeNewTabButton() -> NSButton {
        let button = NSButton(title: "+  New Tab", target: self, action: #selector(newClicked))
        button.isBordered = false
        button.alignment = .left
        button.contentTintColor = .secondaryLabelColor
        button.setAccessibilityIdentifier("nhetrinh.newTab")
        return button
    }

    private func layOut(newTab: NSButton, scroll: NSScrollView) {
        for view in [newTab, scroll] as [NSView] {
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
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// Show `items`; `selected` is the controller's flat tab index. A tab in a collapsed folder has no row
    /// to select: then no row is selected, and its folder is marked.
    func update(_ items: [SidebarItem], selected: Int) {
        nodes = SidebarNode.nodes(items)
        rows = nodes.flatMap { $0.isFolder ? $0.children.map(\.row) : [$0.row] }
        updating = true
        table.reloadData()
        for node in nodes where node.isFolder {
            node.collapsed ? table.collapseItem(node) : table.expandItem(node)
        }
        let row = tabNode(flat: selected).map { table.row(forItem: $0) } ?? -1
        if row >= 0 { table.selectRowIndexes([row], byExtendingSelection: false) } else { table.deselectAll(nil) }
        updating = false
    }

    /// The rows as the outline shows them (a folder row reads its name), and per row whether its tab is
    /// loaded (a folder: no); the selected row (-1: none). Read by the probe (D23).
    var shownRows: [String] { shownNodes.map(\.row.title) }
    var shownLoaded: [Bool] { shownNodes.map(\.row.loaded) }
    var selectedRow: Int { table.selectedRow }

    private var shownNodes: [SidebarNode] { (0..<table.numberOfRows).compactMap(node(atRow:)) }

    func node(atRow row: Int) -> SidebarNode? { table.item(atRow: row) as? SidebarNode }

    func tabNode(flat: Int) -> SidebarNode? {
        nodes.lazy.flatMap { $0.isFolder ? $0.children : [$0] }.first { $0.flat == flat }
    }

    /// Select a tab's row as a click does: the outline reports the change, and `onSelect` shows that tab.
    /// A folder's row is not selected by a click.
    func selectAsClick(_ row: Int) -> Bool {
        guard node(atRow: row)?.isFolder == false else { return false }
        table.selectRowIndexes([row], byExtendingSelection: false)
        return true
    }

    func closeRow(_ row: Int) {
        if let flat = node(atRow: row)?.flat { onClose?(flat) }
    }

    @objc private func newClicked() { onNewTab?() }
}
