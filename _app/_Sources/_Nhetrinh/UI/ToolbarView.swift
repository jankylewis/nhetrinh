import AppKit

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
