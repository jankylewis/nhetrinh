import AppKit
import NhetrinhCore

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
        name.font = AppFont.font(size: NSFont.smallSystemFontSize)
        state.font = AppFont.font(size: NSFont.smallSystemFontSize - 1)
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

    /// The name and the state, in the app's font (P8-FONT-1).
    var textControls: [NSControl] { [name, state] }

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
