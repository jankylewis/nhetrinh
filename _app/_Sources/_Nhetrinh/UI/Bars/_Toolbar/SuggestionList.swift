import AppKit
import NhetrinhCore

/// P11-HISTORY (D30): the address bar's dropdown, under the field, over the page: up to 8 rows (icon if cached,
/// title, url; "Switch to tab" for a page open in a tab). It opens while the user types (`onTyping`, then
/// `show`); ↑ ↓ choose a row, Return or a click opens it (`onOpen`), ⇧⌫ removes it (`onRemove`), Esc closes it.
/// No row is chosen until ↑ or ↓: Return then opens what was typed, as before. Keys: `ToolbarView+Typing`.
final class SuggestionList: NSView {
    static let rowHeight: CGFloat = 36
    var onTyping: ((String) -> Void)?
    var onOpen: ((Suggestion) -> Void)?
    var onRemove: ((Suggestion) -> Void)?
    private(set) var rows: [Suggestion] = []
    /// The chosen row; nil until ↑ or ↓.
    private(set) var chosen: Int?
    private let stack = NSStackView()
    private var height: NSLayoutConstraint?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        isHidden = true
        setAccessibilityIdentifier("nhetrinh.suggestions")
        stack.orientation = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        let height = heightAnchor.constraint(equalToConstant: 0)
        self.height = height
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            height,
        ])
    }

    required init?(coder: NSCoder) { return nil }

    var isOpen: Bool { !isHidden }

    /// The chosen row's suggestion; nil when none is chosen.
    var chosenRow: Suggestion? { chosen.flatMap { rows.indices.contains($0) ? rows[$0] : nil } }

    /// Under `field`, as wide as it, in `field`'s window above every other view.
    func attach(below field: NSView, in container: NSView) {
        guard superview !== container else { return }
        removeFromSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(self, positioned: .above, relativeTo: nil)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: field.bottomAnchor, constant: 4),
            leadingAnchor.constraint(equalTo: field.leadingAnchor),
            trailingAnchor.constraint(equalTo: field.trailingAnchor),
        ])
    }

    /// Show `rows` (with `icons`, one per row, nil: the globe); none closes the list. The choice is cleared.
    func show(_ rows: [Suggestion], icons: [NSImage?]) {
        self.rows = rows
        chosen = nil
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, row) in rows.enumerated() {
            let view = SuggestionRow(row, icon: icons.indices.contains(index) ? icons[index] : nil)
            view.onClick = { [weak self] in self?.open(index) }
            stack.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        height?.constant = CGFloat(rows.count) * Self.rowHeight
        isHidden = rows.isEmpty
        paint()
    }

    func close() { show([], icons: []) }

    /// ↓ (+1) or ↑ (-1): the next or the previous row; past the first row, none (the typed text again).
    func move(_ step: Int) {
        guard !rows.isEmpty else { return }
        let next = (chosen ?? -1) + step
        chosen = next < 0 ? nil : min(next, rows.count - 1)
        paint()
    }

    /// The row at `index` opened, as a click or Return does; the list closes.
    func open(_ index: Int) {
        guard rows.indices.contains(index) else { return }
        let row = rows[index]
        close()
        onOpen?(row)
    }

    /// The rows as they read (the probe, R54): "title — url", and "Switch to tab" when it says so.
    var shownRows: [String] { rows.map { SuggestionRow.text(of: $0) } }

    /// Colours resolve in the view's own appearance, never the process's (NT-BUG-022: dark Mac, light app).
    private func paint() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
        }
        for (index, view) in stack.arrangedSubviews.enumerated() {
            (view as? SuggestionRow)?.isChosen = index == chosen
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        paint()
    }
}
