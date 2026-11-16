import AppKit

/// The vertical tab list. One row per tab; a tab that is not loaded is dimmed.
final class SidebarView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?
    var onNewTab: (() -> Void)?

    private let table = NSTableView()
    private var titles: [String] = []
    private var loaded: [Bool] = []
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
        let close = NSMenuItem(title: "Close Tab", action: #selector(closeClicked), keyEquivalent: "")
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

    func update(titles: [String], loaded: [Bool], selected: Int) {
        self.titles = titles
        self.loaded = loaded
        updating = true
        table.reloadData()
        if selected >= 0 { table.selectRowIndexes([selected], byExtendingSelection: false) }
        updating = false
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int { titles.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("cell")
        let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTextField ?? makeCell(identifier)
        cell.stringValue = titles[row]
        cell.textColor = loaded[row] ? .labelColor : .tertiaryLabelColor
        return cell
    }

    private func makeCell(_ identifier: NSUserInterfaceItemIdentifier) -> NSTextField {
        let cell = NSTextField(labelWithString: "")
        cell.identifier = identifier
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !updating, table.selectedRow >= 0 else { return }
        onSelect?(table.selectedRow)
    }

    @objc private func closeClicked() {
        if table.clickedRow >= 0 { onClose?(table.clickedRow) }
    }

    @objc private func newClicked() { onNewTab?() }
}
