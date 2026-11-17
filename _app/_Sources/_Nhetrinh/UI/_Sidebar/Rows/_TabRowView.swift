import AppKit

/// One sidebar row: the site's icon (16 pt), the title, and a close button shown while the pointer
/// is over the row (P2). A row with no icon of its own shows a dim globe.
final class TabRowView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("tab-row")
    private static let noIcon = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)

    var onClose: (() -> Void)?
    private let icon = NSImageView()
    private let title = NSTextField(labelWithString: "")
    private let close = NSButton()
    private var hover: NSTrackingArea?

    init() {
        super.init(frame: .zero)
        identifier = Self.identifier
        title.lineBreakMode = .byTruncatingTail
        close.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close Tab")
        close.isBordered = false
        close.target = self
        close.action = #selector(closeClicked)
        close.setAccessibilityLabel("Close Tab")
        close.isHidden = true
        imageView = icon
        textField = title
        AppFont.apply(to: textControls)
        layOut()
    }

    required init?(coder: NSCoder) { return nil }

    private func layOut() {
        for view in [icon, title, close] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.trailingAnchor.constraint(equalTo: close.leadingAnchor, constant: -4),
            close.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            close.centerYAnchor.constraint(equalTo: centerYAnchor),
            close.widthAnchor.constraint(equalToConstant: 16),
        ])
    }

    func show(_ row: SidebarView.Row) {
        title.stringValue = row.title
        title.textColor = row.loaded ? .labelColor : .tertiaryLabelColor
        icon.image = row.icon ?? Self.noIcon
        icon.alphaValue = row.icon == nil || !row.loaded ? 0.5 : 1
        close.isHidden = !isPointerInside
    }

    /// The row's text in the app's font (P8-FONT-1).
    var textControls: [NSControl] { [title] }

    /// Whether the row shows a site icon, not the globe of a row with none.
    var showsSiteIcon: Bool { icon.image != nil && icon.image !== Self.noIcon }

    // MARK: - Hover

    private var isPointerInside: Bool {
        guard let window else { return false }
        return bounds.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil))
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        hover.map(removeTrackingArea)
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                  owner: self)
        addTrackingArea(area)
        hover = area
    }

    override func mouseEntered(with event: NSEvent) { close.isHidden = false }
    override func mouseExited(with event: NSEvent) { close.isHidden = true }

    @objc private func closeClicked() { onClose?() }
}
