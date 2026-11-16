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
}

/// JavaScript `alert`, `confirm` and `prompt`: before P3 WebKit answered them alone (`confirm` said no).
extension BrowserWindowController {
    /// Show `alert` as a sheet on the window, the asking tab selected first. `done` gets the index of
    /// the button pressed, 0 for the first; -1 when there is no window to show it on.
    func ask(_ alert: NSAlert, for webView: WKWebView?, done: @escaping (Int) -> Void) {
        guard let window else { return done(-1) }
        if let index = tabs.firstIndex(where: { $0.webView === webView && webView != nil }), index != selected {
            select(index)
        }
        sheets.shown += 1
        alert.beginSheetModal(for: window) { response in
            done(response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue)
        }
    }

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
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        ask(alert, for: webView) { completionHandler($0 == 0 ? field.stringValue : nil) }
    }
}
