import AppKit

/// Back, forward, reload and the address field.
final class ToolbarView: NSView {
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?
    var onSubmit: ((String) -> Void)?

    let address = NSTextField()
    private lazy var back = makeButton("chevron.left", "Back", #selector(tapBack))
    private lazy var forward = makeButton("chevron.right", "Forward", #selector(tapForward))
    private lazy var reload = makeButton("arrow.clockwise", "Reload", #selector(tapReload))

    override init(frame: NSRect) {
        super.init(frame: frame)
        address.placeholderString = "Search or enter address"
        address.bezelStyle = .roundedBezel
        address.focusRingType = .none
        address.target = self
        address.action = #selector(submit)
        address.setAccessibilityIdentifier("nhetrinh.address")

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

    required init?(coder: NSCoder) { return nil }

    func update(url: URL?, canBack: Bool, canForward: Bool) {
        back.isEnabled = canBack
        forward.isEnabled = canForward
        // Never replace the text while the user is typing in the field.
        if window?.firstResponder != address.currentEditor() {
            address.stringValue = url?.absoluteString ?? ""
        }
    }

    @objc private func tapBack() { onBack?() }
    @objc private func tapForward() { onForward?() }
    @objc private func tapReload() { onReload?() }
    @objc private func submit() { onSubmit?(address.stringValue) }

    /// A borderless symbol button; `label` is its accessibility name and its identifier suffix.
    private func makeButton(_ symbol: String, _ label: String, _ action: Selector) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label) ?? NSImage()
        let button = NSButton(image: image, target: self, action: action)
        button.isBordered = false
        button.setAccessibilityLabel(label)
        button.setAccessibilityIdentifier("nhetrinh." + label.lowercased())
        button.widthAnchor.constraint(equalToConstant: 28).isActive = true
        return button
    }
}
