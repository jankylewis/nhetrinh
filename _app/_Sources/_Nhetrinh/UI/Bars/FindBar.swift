import AppKit

/// The find bar under the toolbar (P4): a search field, Previous, Next, the answer, Close.
/// Return finds the next match, Esc closes the bar. WebKit answers found or not found, no count.
final class FindBar: NSView, NSSearchFieldDelegate {
    static let height: CGFloat = 32
    var onFind: ((String, Bool) -> Void)?
    var onClose: (() -> Void)?

    let field = NSSearchField()
    private let answer = NSTextField(labelWithString: "")
    private lazy var previous = button("Previous", #selector(tapPrevious))
    private lazy var next = button("Next", #selector(tapNext))
    private lazy var close = button("Close", #selector(tapClose))

    override init(frame: NSRect) {
        super.init(frame: frame)
        field.placeholderString = "Find on this page"
        field.sendsWholeSearchString = true
        field.target = self
        field.action = #selector(tapNext)
        field.delegate = self
        answer.textColor = .secondaryLabelColor
        AppFont.apply(to: textControls)
        let row = NSStackView(views: [field, previous, next, answer, NSView(), close])
        row.spacing = 6
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 240),
        ])
    }

    required init?(coder: NSCoder) { return nil }

    /// The field, the answer and the buttons, in the app's font (P8-FONT-1).
    var textControls: [NSControl] { [field, answer, previous, next, close] }

    /// The last answer as the readback reads it: "found", "not found", or "" before any search.
    private(set) var result = ""

    func show(found: Bool?) {
        result = found.map { $0 ? "found" : "not found" } ?? ""
        answer.stringValue = found == false ? "Not found" : ""
    }

    /// Esc in the field closes the bar.
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(NSResponder.cancelOperation(_:)) else { return false }
        onClose?()
        return true
    }

    /// Press a button by its title, as a click does (the readback probe, R27).
    func press(_ label: String) -> Bool {
        guard !isHidden, let button = [previous, next, close].first(where: { $0.title == label }) else { return false }
        button.performClick(nil)
        return true
    }

    @objc private func tapNext() { onFind?(field.stringValue, false) }
    @objc private func tapPrevious() { onFind?(field.stringValue, true) }
    @objc private func tapClose() { onClose?() }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.controlSize = .small
        return button
    }
}
