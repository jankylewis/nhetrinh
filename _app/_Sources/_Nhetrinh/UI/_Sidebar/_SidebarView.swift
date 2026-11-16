import AppKit
import NhetrinhCore

/// The vertical tab list. One row per tab (`TabRowView`): icon, title, close button on hover; a tab
/// that is not loaded is dimmed. A row's menu and a middle click close it; a drag reorders (P2).
final class SidebarView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    struct Row {
        let title: String
        let loaded: Bool
        let icon: NSImage?
    }

    static let rowType = NSPasteboard.PasteboardType("nhetrinh.tab-row")

    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onNewTab: (() -> Void)?
    /// A row dragged from `from` to `to` (its index once moved).
    var onMove: ((Int, Int) -> Void)?

    let table = TabTable()
    /// P5: the footer's download rows (`../Bars/DownloadsBar.swift`), below the tabs.
    let downloads = DownloadsBar()
    private var rows: [Row] = []
    private var updating = false

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

    private func configureTable() {
        table.addTableColumn(NSTableColumn(identifier: .init("tab")))
        table.headerView = nil
        table.style = .sourceList
        table.rowHeight = 28
        table.backgroundColor = .clear
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityIdentifier("nhetrinh.sidebar")
        table.registerForDraggedTypes([Self.rowType])
        table.setDraggingSourceOperationMask(.move, forLocal: true)
        table.onMiddleClick = { [weak self] row in self?.onClose?(row) }
        let close = NSMenuItem(title: "Close Tab", action: #selector(closeFromMenu), keyEquivalent: "")
        close.target = self
        table.menu = NSMenu()
        table.menu?.addItem(close)
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

    func update(_ rows: [Row], selected: Int) {
        self.rows = rows
        updating = true
        table.reloadData()
        if selected >= 0 { table.selectRowIndexes([selected], byExtendingSelection: false) }
        updating = false
    }

    /// The rows as the table shows them, and the selected row (-1: none). Read by the probe (D23).
    var shownRows: [String] { Array(rows.map(\.title).prefix(table.numberOfRows)) }
    var selectedRow: Int { table.selectedRow }

    /// Select a row as a click does: the table reports the change, and `onSelect` shows that tab.
    func selectAsClick(_ row: Int) -> Bool {
        guard row >= 0, row < table.numberOfRows else { return false }
        table.selectRowIndexes([row], byExtendingSelection: false)
        return true
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: TabRowView.identifier, owner: nil) as? TabRowView ?? TabRowView()
        cell.show(rows[row])
        cell.onClose = { [weak self, weak cell] in
            guard let self, let cell else { return }
            let index = self.table.row(for: cell)
            if index >= 0 { self.onClose?(index) }
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !updating, table.selectedRow >= 0 else { return }
        onSelect?(table.selectedRow)
    }

    @objc private func closeFromMenu() {
        if table.menuRow >= 0 { onClose?(table.menuRow) }
    }

    @objc private func newClicked() { onNewTab?() }
}
