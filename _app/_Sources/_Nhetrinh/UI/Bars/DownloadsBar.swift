import AppKit
import NhetrinhCore

/// P5: the sidebar footer, one row per download it shows (`DownloadList.shownItems`: every running one,
/// P5-FIX-1 F2): name, then progress or the state ("done", "stalled", "failed: <reason>", "cancelled"), and
/// Cancel while it runs. Past 3 rows it scrolls. A click on a finished row asks Finder to show the file.
/// Hidden while there is no download.
final class DownloadsBar: NSView {
    static let rowHeight: CGFloat = 34
    var onCancel: ((Int) -> Void)?
    var onReveal: ((Int) -> Void)?
    private let stack = NSStackView()
    private let scroll = NSScrollView()
    private var rows: [DownloadRow] = []
    private var items: [DownloadItem] = []
    private var height: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 8, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.documentView = stack
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        let height = heightAnchor.constraint(equalToConstant: 0)
        self.height = height
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor), height,
        ])
        setAccessibilityIdentifier("nhetrinh.downloads")
        show([])
    }

    required init?(coder: NSCoder) { return nil }

    func show(_ items: [DownloadItem]) {
        self.items = items
        while rows.count < items.count { addRow() }
        for (index, row) in rows.enumerated() {
            row.isHidden = !items.indices.contains(index)
            if items.indices.contains(index) { row.show(items[index]) }
        }
        let shown = CGFloat(min(items.count, DownloadList.shown))
        height?.constant = items.isEmpty ? 0 : shown * (Self.rowHeight + stack.spacing) + 14
        isHidden = items.isEmpty
    }

    /// The rows shown now (the tests read them).
    var shownRowCount: Int { rows.filter { !$0.isHidden }.count }

    private func addRow() {
        let row = DownloadRow()
        let index = rows.count
        row.cancel.tag = index
        row.cancel.target = self
        row.cancel.action = #selector(cancelClicked(_:))
        row.onClick = { [weak self] in self?.rowClicked(index) }
        rows.append(row)
        stack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -20).isActive = true
    }

    /// The probe's `download` (D23): the row's Cancel pressed, or the row clicked ("Show in Finder"),
    /// as the user does. False when the row or its control is not shown.
    func press(row: Int, item: String) -> Bool {
        guard items.indices.contains(row) else { return false }
        switch item {
        case "Cancel":
            guard !rows[row].cancel.isHidden else { return false }
            rows[row].cancel.performClick(nil)
        case "Show in Finder": rowClicked(row)
        default: return false
        }
        return true
    }

    @objc private func cancelClicked(_ sender: NSButton) { onCancel?(sender.tag) }

    private func rowClicked(_ index: Int) {
        if items.indices.contains(index), items[index].state == .finished { onReveal?(index) }
    }
}
