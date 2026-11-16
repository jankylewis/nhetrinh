import AppKit

/// Vertical tab list. Rows are plain text; unloaded tabs are dimmed.
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
        let column = NSTableColumn(identifier: .init("tab"))
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .sourceList
        table.rowHeight = 28
        table.dataSource = self
        table.delegate = self
        table.backgroundColor = .clear
        table.menu = NSMenu()
        table.menu?.addItem(NSMenuItem(title: "Close Tab", action: #selector(closeClicked), keyEquivalent: ""))
        table.menu?.items.first?.target = self

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        let newTab = NSButton(title: "+  New Tab", target: self, action: #selector(newClicked))
        newTab.isBordered = false
        newTab.alignment = .left
        newTab.contentTintColor = .secondaryLabelColor

        for v in [scroll, newTab] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            newTab.topAnchor.constraint(equalTo: topAnchor, constant: 44),  // below traffic lights
            newTab.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            newTab.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scroll.topAnchor.constraint(equalTo: newTab.bottomAnchor, constant: 6),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func update(titles: [String], loaded: [Bool], selected: Int) {
        self.titles = titles
        self.loaded = loaded
        updating = true
        table.reloadData()
        if selected >= 0 { table.selectRowIndexes([selected], byExtendingSelection: false) }
        updating = false
    }

    func numberOfRows(in tableView: NSTableView) -> Int { titles.count }

    func tableView(_ tv: NSTableView, viewFor col: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("cell")
        let cell = tv.makeView(withIdentifier: id, owner: nil) as? NSTextField ?? {
            let f = NSTextField(labelWithString: "")
            f.identifier = id
            f.lineBreakMode = .byTruncatingTail
            return f
        }()
        cell.stringValue = titles[row]
        cell.textColor = loaded[row] ? .labelColor : .tertiaryLabelColor
        return cell
    }

    func tableViewSelectionDidChange(_ n: Notification) {
        guard !updating, table.selectedRow >= 0 else { return }
        onSelect?(table.selectedRow)
    }

    @objc private func closeClicked() { if table.clickedRow >= 0 { onClose?(table.clickedRow) } }
    @objc private func newClicked() { onNewTab?() }
}

/// Back / forward / reload + address field.
final class ToolbarView: NSView, NSTextFieldDelegate {
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?
    var onSubmit: ((String) -> Void)?

    let address = NSTextField()
    private let back = ToolbarView.button("chevron.left")
    private let forward = ToolbarView.button("chevron.right")
    private let reload = ToolbarView.button("arrow.clockwise")

    override init(frame: NSRect) {
        super.init(frame: frame)
        back.target = self; back.action = #selector(tapBack)
        forward.target = self; forward.action = #selector(tapForward)
        reload.target = self; reload.action = #selector(tapReload)
        address.placeholderString = "Search or enter address"
        address.bezelStyle = .roundedBezel
        address.focusRingType = .none
        address.delegate = self
        address.target = self
        address.action = #selector(submit)

        let row = NSStackView(views: [back, forward, reload, address])
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    func update(url: URL?, canBack: Bool, canForward: Bool) {
        back.isEnabled = canBack
        forward.isEnabled = canForward
        if window?.firstResponder != address.currentEditor() {
            address.stringValue = url?.absoluteString ?? ""
        }
    }

    @objc private func tapBack() { onBack?() }
    @objc private func tapForward() { onForward?() }
    @objc private func tapReload() { onReload?() }
    @objc private func submit() { onSubmit?(address.stringValue) }

    private static func button(_ symbol: String) -> NSButton {
        let b = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: symbol)!,
                         target: nil, action: nil)
        b.isBordered = false
        b.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return b
    }
}
