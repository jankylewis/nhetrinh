import AppKit
import NhetrinhCore
import WebKit

/// The readback probe's P3 answers (D23): the window's sheet read as it shows, its button pressed and
/// its field typed in as a user does, and a left click on an element of the page, sent to this app only.
extension BrowserWindowController {
    /// The browser window's sheet, else the Settings Hub's (P4: Clear Website Data…).
    var shownSheet: NSWindow? { window?.attachedSheet ?? hub?.window?.attachedSheet }

    /// P4: the find bar, the zoom badge, the window's look, the Settings Hub.
    private func readTools(into state: inout ProbeState) {
        state.findShown = !findBar.isHidden
        state.findResult = findBar.result
        state.zoomBadge = toolbar.zoomText
        let look = window?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        state.appearance = look == .darkAqua ? "dark" : "light"
        state.hubShown = hub?.window?.isVisible ?? false
    }

    /// P4's probe ops: the find bar's field, a Settings Hub control.
    func toolAnswer(_ request: ProbeRequest) -> ProbeResponse {
        switch request {
        case .find(let text): return typeInFindBar(text)
        case .setting(let name, let value):
            guard let hub, hub.window?.isVisible == true else { return .failed("the Settings Hub is not shown") }
            return hub.set(name, to: value) ? .done : .failed("the Settings Hub has no \(name) \(value)")
        default: return .failed("not a tool request")
        }
    }

    /// The probe's `find`: typed into the shown bar, then Return.
    func typeInFindBar(_ text: String) -> ProbeResponse {
        guard !findBar.isHidden else { return .failed("the find bar is not shown") }
        findBar.field.stringValue = text
        let sent = findBar.field.sendAction(findBar.field.action, to: findBar.field.target)
        return sent ? .done : .failed("the find bar's field did not submit")
    }

    func readSheet(into state: inout ProbeState) {
        state.sheetsShown = sheets.shown
        state.handedOff = sheets.handedOff
        state.fullscreen = NSApp.windows.contains { $0.isVisible && $0.styleMask.contains(.fullScreen) }
        state.active = NSApp.isActive
        readTools(into: &state)
        guard let sheet = shownSheet else { return }
        state.sheetKind = sheet === sheets.openPanel ? "open" : sheets.printing ? "print" : "alert"
        let views = Self.views(in: sheet.contentView)
        state.sheet = views.compactMap { $0 as? NSTextField }.filter { !$0.isEditable && !$0.stringValue.isEmpty }
            .map(\.stringValue).joined(separator: "\n")
        state.sheetButtons = views.compactMap { $0 as? NSButton }.filter { !($0 is NSPopUpButton) && !$0.title.isEmpty }
            .map(\.title)
    }

    /// The open panel is the system's: only its Cancel is pressed, through the panel itself.
    func pressSheetButton(_ label: String) -> ProbeResponse {
        guard let sheet = shownSheet else { return .failed("no sheet is shown") }
        if let panel = sheets.openPanel, sheet === panel {
            guard label == "Cancel" else { return .failed("the open panel is the system's: only Cancel is pressed") }
            DispatchQueue.main.async { panel.cancel(nil) }
            return .done
        }
        let buttons = Self.views(in: sheet.contentView).compactMap { $0 as? NSButton }
        guard let button = buttons.first(where: { $0.title == label && !($0 is NSPopUpButton) }) else {
            return .failed("the sheet has no button \(label)")
        }
        DispatchQueue.main.async { button.performClick(nil) }  // after the answer: the sheet may end a page's wait
        return .done
    }

    func typeInSheet(field index: Int, _ text: String) -> ProbeResponse {
        guard let sheet = shownSheet else { return .failed("no sheet is shown") }
        let fields = Self.views(in: sheet.contentView).compactMap { $0 as? NSTextField }.filter(\.isEditable)
        guard fields.indices.contains(index) else { return .failed("the sheet has \(fields.count) field(s)") }
        fields[index].stringValue = text
        return .done
    }

    /// D25: the readback asks for this only in R26a and R26b, and only when run with `--allow-focus`:
    /// WebKit refuses fullscreen, camera and microphone in a page it counts as hidden.
    func comeToFront() -> ProbeResponse {
        guard let window else { return .failed("the browser window is gone") }
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()  // in front even when macOS does not let the app become active
        return .done
    }

    static let elementCenter = """
        const e = document.querySelector(selector); if (!e) return null; e.scrollIntoView({block: 'center'})
        const r = e.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2]
        """

    /// A left click on the first element `selector` finds; the answer comes before the click.
    func clickInPage(_ selector: String) -> ProbeResponse {
        guard let webView = current else { return .failed("no page is shown") }
        webView.callAsyncJavaScript(Self.elementCenter, arguments: ["selector": selector], in: nil, in: .page) {
            [weak self, weak webView] result in
            guard let self, let webView, case .success(let value) = result, let center = value as? [Double],
                  center.count == 2 else { return Log.app.error("probe: the page has no element to click") }
            self.sendMouse([.leftMouseDown, .leftMouseUp], to: webView, at: center)
        }
        return .done
    }

    static func views(in root: NSView?) -> [NSView] {
        guard let root else { return [] }
        return [root] + root.subviews.flatMap { views(in: $0) }
    }
}
