import AppKit
import NhetrinhCore

/// P5: the sidebar footer, up to 3 download rows (`DownloadList.shown`): name, then progress or
/// the state ("done", "failed: <reason>", "cancelled"), and Cancel while it runs. A click on a
/// finished row asks Finder to show the file. Hidden while there is no download.
final class DownloadsBar: NSStackView {
    var onCancel: ((Int) -> Void)?
    var onReveal: ((Int) -> Void)?
    private let rows = (0..<DownloadList.shown).map { _ in DownloadRow() }
    private var items: [DownloadItem] = []

    init() {
        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = 4
        edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 8, right: 8)
        setAccessibilityIdentifier("nhetrinh.downloads")
        for (index, row) in rows.enumerated() {
            row.cancel.tag = index
            row.cancel.target = self
            row.cancel.action = #selector(cancelClicked(_:))
            row.onClick = { [weak self] in self?.rowClicked(index) }
            addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: widthAnchor, constant: -20).isActive = true
        }
        show([])
    }

    required init?(coder: NSCoder) { return nil }

    func show(_ items: [DownloadItem]) {
        self.items = items
        for (index, row) in rows.enumerated() {
            row.isHidden = !items.indices.contains(index)
            if items.indices.contains(index) { row.show(items[index]) }
        }
        isHidden = items.isEmpty
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

/// One download row: name over progress or state, Cancel at the right while it runs.
final class DownloadRow: NSView {
    var onClick: (() -> Void)?
    let cancel = NSButton()
    private let name = NSTextField(labelWithString: "")
    private let state = NSTextField(labelWithString: "")
    private let bar = NSProgressIndicator()

    init() {
        super.init(frame: .zero)
        name.lineBreakMode = .byTruncatingMiddle
        name.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        state.font = .systemFont(ofSize: NSFont.smallSystemFontSize - 1)
        state.textColor = .secondaryLabelColor
        state.lineBreakMode = .byTruncatingTail
        bar.style = .bar
        bar.controlSize = .small
        bar.minValue = 0
        bar.maxValue = 1
        cancel.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Cancel")
        cancel.isBordered = false
        cancel.setAccessibilityLabel("Cancel")
        layOut()
    }

    required init?(coder: NSCoder) { return nil }

    private func layOut() {
        for view in [name, state, bar, cancel] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            name.topAnchor.constraint(equalTo: topAnchor),
            name.leadingAnchor.constraint(equalTo: leadingAnchor),
            name.trailingAnchor.constraint(equalTo: cancel.leadingAnchor, constant: -4),
            state.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 1),
            state.leadingAnchor.constraint(equalTo: leadingAnchor),
            state.trailingAnchor.constraint(equalTo: name.trailingAnchor),
            state.bottomAnchor.constraint(equalTo: bottomAnchor),
            bar.centerYAnchor.constraint(equalTo: state.centerYAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            bar.trailingAnchor.constraint(equalTo: name.trailingAnchor),
            cancel.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancel.trailingAnchor.constraint(equalTo: trailingAnchor),
            cancel.widthAnchor.constraint(equalToConstant: 16),
        ])
    }

    func show(_ item: DownloadItem) {
        name.stringValue = item.name
        state.stringValue = item.stateText
        let running: Double??
        if case .running(let done) = item.state { running = done } else { running = nil }
        cancel.isHidden = running == nil
        bar.isHidden = running == nil
        bar.isIndeterminate = running.flatMap { $0 } == nil
        bar.doubleValue = running.flatMap { $0 } ?? 0
        toolTip = item.state == .finished ? "Show in Finder" : item.stateText
    }

    override func mouseUp(with event: NSEvent) { onClick?() }
}
