import AppKit

/// Back, forward, reload and the address field. While a page loads, reload is stop and a thin line
/// along the bottom edge shows the progress (P2).
final class ToolbarView: NSView {
    var onBack: (() -> Void)?
    var onForward: (() -> Void)?
    var onReload: (() -> Void)?
    var onStop: (() -> Void)?
    var onSubmit: ((String) -> Void)?

    let address = NSTextField()
    private lazy var back = makeButton("chevron.left", "Back", #selector(tapBack))
    private lazy var forward = makeButton("chevron.right", "Forward", #selector(tapForward))
    private lazy var reload = makeButton("arrow.clockwise", "Reload", #selector(tapReload))
    private let progressLine = NSView()
    private var loading = false
    private var progress = 0.0

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
        progressLine.wantsLayer = true
        progressLine.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        progressLine.isHidden = true
        addSubview(progressLine)
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
    /// The reload button's label as it reads now: "Reload", or "Stop" while the page loads.
    var reloadLabel: String { reload.accessibilityLabel() ?? "" }

    func showLoading(_ isLoading: Bool, progress: Double) {
        self.progress = isLoading ? progress : 0
        progressLine.isHidden = !isLoading
        needsLayout = true
        guard isLoading != loading else { return }
        loading = isLoading
        let (symbol, label) = isLoading ? ("xmark", "Stop") : ("arrow.clockwise", "Reload")
        reload.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        reload.setAccessibilityLabel(label)
    }

    override func layout() {
        super.layout()
        progressLine.frame = NSRect(x: 0, y: 0, width: bounds.width * CGFloat(min(1, max(0.05, progress))), height: 2)
    }

    /// Whether the progress line shows, and its width (the probe, R18, and the tests).
    var progressShown: Bool { !progressLine.isHidden }
    var progressWidth: CGFloat { progressLine.frame.width }

    /// Press a button by its label, as a click does (the readback probe, R18).
    func press(_ label: String) -> Bool {
        guard let button = [back, forward, reload].first(where: { $0.accessibilityLabel() == label }),
              button.isEnabled else { return false }
        button.performClick(nil)
        return true
    }

    @objc private func tapReload() { loading ? onStop?() : onReload?() }
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
