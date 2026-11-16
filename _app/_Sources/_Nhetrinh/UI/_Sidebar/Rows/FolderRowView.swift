import AppKit

/// A folder's sidebar row (P7): a folder icon and the name. A collapsed folder that holds the selected
/// tab is marked: the name in bold and a dot after it, so the selection is never lost from sight.
final class FolderRowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("folder-row")
    private static let folderIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Folder")

    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let mark = NSTextField(labelWithString: "●")

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier
        icon.image = Self.folderIcon
        title.lineBreakMode = .byTruncatingTail
        mark.textColor = .controlAccentColor
        mark.font = .systemFont(ofSize: 8)
        mark.setAccessibilityLabel("holds the selected tab")
        imageView = icon
        textField = title
        for view in [icon, title, mark] as [NSView] {
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
            mark.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
        ])
    }

    required init?(coder: NSCoder) { return nil }

    func shown(_ node: SidebarNode) -> FolderRowView {
        title.stringValue = node.row.title
        let size = NSFont.systemFontSize
        title.font = node.marked ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        mark.isHidden = !node.marked
        return self
    }

    /// Whether the row shows the mark (read by the tests).
    var isMarked: Bool { !mark.isHidden }
}
