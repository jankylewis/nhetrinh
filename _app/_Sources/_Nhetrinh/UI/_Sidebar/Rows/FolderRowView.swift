import AppKit

/// A group's sidebar row (P7; P8-GROUPS-1): a folder icon, the name, and its tab count at the right. A
/// collapsed group that holds the selected tab is marked: the name in bold and a dot after it, so the
/// selection is never lost from sight. The outline indents it by its level.
final class FolderRowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("folder-row")
    private static let folderIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Group")

    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let mark = NSTextField(labelWithString: "●")
    private let count = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier
        icon.image = Self.folderIcon
        title.lineBreakMode = .byTruncatingTail
        mark.textColor = .controlAccentColor
        mark.font = AppFont.font(size: 8)
        mark.setAccessibilityLabel("holds the selected tab")
        styleCount()
        imageView = icon
        textField = title
        for view in [icon, title, mark, count] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            mark.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 4),
            mark.centerYAnchor.constraint(equalTo: centerYAnchor),
            mark.trailingAnchor.constraint(lessThanOrEqualTo: count.leadingAnchor, constant: -4),
            count.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            count.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { return nil }

    /// The tab count: small, secondary, never cut; the name is cut first.
    private func styleCount() {
        count.textColor = .secondaryLabelColor
        count.font = AppFont.font(size: NSFont.smallSystemFontSize)
        count.setContentCompressionResistancePriority(.required, for: .horizontal)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    func shown(_ node: SidebarNode) -> FolderRowView {
        title.stringValue = node.row.title
        title.font = AppFont.font(size: NSFont.systemFontSize, bold: node.marked)
        mark.isHidden = !node.marked
        count.stringValue = "\(node.count)"
        count.setAccessibilityLabel(node.count == 1 ? "1 tab" : "\(node.count) tabs")
        return self
    }

    /// The row's text in the app's font (P8-FONT-1).
    var textControls: [NSControl] { [title, mark, count] }

    /// Whether the row shows the mark (read by the tests).
    var isMarked: Bool { !mark.isHidden }

    /// The tab count the row shows (read by the tests).
    var shownCount: String { count.stringValue }
}
