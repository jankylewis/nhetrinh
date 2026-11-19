import AppKit
import NhetrinhCore

/// One dropdown row (P11-HISTORY): the site's icon (the globe when none is cached), the title over the url, in
/// the app's font (P8-FONT-1); "Switch to tab" at the end for a page open in a tab. A click opens it.
final class SuggestionRow: NSView {
    static let switchText = "Switch to tab"
    var onClick: (() -> Void)?
    var isChosen = false { didSet { paint() } }
    private let title: NSTextField
    private let url: NSTextField

    init(_ row: Suggestion, icon: NSImage?) {
        title = NSTextField(labelWithString: row.title.isEmpty ? row.url : row.title)
        url = NSTextField(labelWithString: row.url)
        super.init(frame: .zero)
        wantsLayer = true
        let image = NSImageView(image: icon ?? NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
            ?? NSImage())
        image.widthAnchor.constraint(equalToConstant: 16).isActive = true
        var views: [NSView] = [image, Self.lines(title, url)]
        if row.tab != nil { views.append(NSTextField(labelWithString: Self.switchText)) }
        let line = NSStackView(views: views)
        line.distribution = .fill
        line.spacing = 8
        line.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        configureLabels()
        AppFont.apply(to: AppFont.controls(in: line))
        url.font = AppFont.font(size: NSFont.smallSystemFontSize)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: SuggestionList.rowHeight),
            line.leadingAnchor.constraint(equalTo: leadingAnchor),
            line.trailingAnchor.constraint(equalTo: trailingAnchor),
            line.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityLabel(Self.text(of: row))
    }

    required init?(coder: NSCoder) { return nil }

    /// The title over the url; it takes the free width, so "Switch to tab" sits at the end (NT-BUG-022).
    private static func lines(_ title: NSTextField, _ url: NSTextField) -> NSStackView {
        let lines = NSStackView(views: [title, url])
        lines.orientation = .vertical
        lines.alignment = .leading
        lines.spacing = 1
        lines.setContentHuggingPriority(.init(1), for: .horizontal)
        return lines
    }

    private func configureLabels() {
        url.textColor = .secondaryLabelColor
        for field in [title, url] {
            field.lineBreakMode = .byTruncatingTail
            field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
    }

    /// What the row reads: "title — url", with " — Switch to tab" for an open tab.
    static func text(of row: Suggestion) -> String {
        let title = row.title.isEmpty ? row.url : row.title
        return "\(title) — \(row.url)" + (row.tab == nil ? "" : " — \(switchText)")
    }

    override func mouseDown(with event: NSEvent) { onClick?() }

    /// In the row's own appearance (NT-BUG-022).
    private func paint() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = isChosen
                ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).cgColor : NSColor.clear.cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        paint()
    }
}
