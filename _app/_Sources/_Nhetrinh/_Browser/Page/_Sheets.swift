import AppKit
import NhetrinhCore
import WebKit

/// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md): what the window's sheets need to keep. Every question a
/// page asks is a sheet on the window, never a free panel: it belongs to the tab that asked.
final class Sheets {
    /// Sheets shown since launch; the open panel while it is shown; whether the print panel is.
    var shown = 0
    var openPanel: NSOpenPanel?
    var printing = false
    /// Camera and microphone answers per site, until the app quits.
    var permissions = SitePermissions()
    /// Links handed to another app through macOS since launch.
    var handedOff = 0
    /// The sheets a page waits on, with that page's web view: they end with the page (S1).
    var waiting: [(sheet: NSWindow, page: ObjectIdentifier)] = []
}

/// JavaScript `alert`, `confirm` and `prompt`: before P3 WebKit answered them alone (`confirm` said no).
extension BrowserWindowController {
    /// Show `alert` as a sheet on the window, the asking tab selected first. `done` gets the index of
    /// the button pressed, 0 for the first; -1 when nothing was pressed: no window to show it on, or the
    /// page's tab was closed or left first (S1).
    func ask(_ alert: NSAlert, for webView: WKWebView?, done: @escaping (Int) -> Void) {
        guard let window else { return done(-1) }
        if let index = tabs.firstIndex(where: { $0.webView === webView && webView != nil }), index != selected {
            select(index)
        }
        sheets.shown += 1
        let sheet = alert.window
        keep(sheet, for: webView)
        alert.beginSheetModal(for: window) { [weak self] response in
            self?.forget(sheet)
            let first = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
            done(response == .abort ? -1 : response.rawValue - first)
        }
    }

    /// A page's sheets end with the page: its tab closes or is left (S1). Nothing is pressed, so the page
    /// hears "no answer": `alert` goes on, `confirm` false, `prompt` nil, the sign-in and the open panel
    /// are cancelled, a site is not remembered as refused. The menu items stay on: ⌘W and ⌃⇥ work.
    func endSheets(of webView: WKWebView?) {
        guard let webView, let window else { return }
        let page = ObjectIdentifier(webView)
        for entry in sheets.waiting where entry.page == page {
            if let panel = entry.sheet as? NSSavePanel { panel.cancel(nil) } else {
                window.endSheet(entry.sheet, returnCode: .abort)
            }
        }
    }

    func keep(_ sheet: NSWindow, for webView: WKWebView?) {
        guard let webView else { return }
        sheets.waiting.append((sheet, ObjectIdentifier(webView)))
    }

    func forget(_ sheet: NSWindow) { sheets.waiting.removeAll { $0.sheet === sheet } }

    /// A sheet with the page's text, the site it comes from and these buttons.
    static func pageAlert(_ text: String, from frame: WKFrameInfo, buttons: [String]) -> NSAlert {
        let alert = NSAlert()
        let host = frame.securityOrigin.host
        alert.messageText = host.isEmpty ? "This page says" : "\(host) says"
        alert.informativeText = text
        buttons.forEach { alert.addButton(withTitle: $0) }
        return alert
    }

    @objc func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                       initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        ask(Self.pageAlert(message, from: frame, buttons: ["OK"]), for: webView) { _ in completionHandler() }
    }

    @objc func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                       initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = Self.pageAlert(message, from: frame, buttons: ["OK", "Cancel"])
        ask(alert, for: webView) { completionHandler($0 == 0) }
    }

    @objc func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
                       defaultText: String?, initiatedByFrame frame: WKFrameInfo,
                       completionHandler: @escaping (String?) -> Void) {
        let alert = Self.pageAlert(prompt, from: frame, buttons: ["OK", "Cancel"])
        let field = NSTextField(string: defaultText ?? "")
        field.frame = NSRect(x: 0, y: 0, width: 280, height: 24)
        AppFont.apply(to: [field])
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        ask(alert, for: webView) { completionHandler($0 == 0 ? field.stringValue : nil) }
    }
}
