import AppKit
import NhetrinhCore
import WebKit

/// P3: a link to another app (`mailto:`, `tel:`, meeting apps): the app asks, then hands it to macOS.
/// Nothing leaves the browser without the user's Open.
extension BrowserWindowController {
    /// Whether `url` leaves the browser; if so the ask sheet is shown. Only a link the user followed or
    /// a load of the whole page asks: a frame of the page that loads another app's link is refused quietly.
    func leaves(_ url: URL, from webView: WKWebView, asked: Bool) -> Bool {
        guard ExternalScheme.leaves(url) else { return false }
        if asked { askToLeave(url, from: webView) }
        return true
    }

    private func askToLeave(_ url: URL, from webView: WKWebView) {
        let alert = NSAlert()
        let scheme = url.scheme ?? ""
        let app = NSWorkspace.shared.urlForApplication(toOpen: url)
        alert.informativeText = String(url.absoluteString.prefix(300))
        guard let app else {
            alert.messageText = "No app on this Mac opens \(scheme): links"
            alert.addButton(withTitle: "OK")
            return ask(alert, for: webView) { _ in }
        }
        alert.messageText = "Open this link in \(app.deletingPathExtension().lastPathComponent)?"
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        ask(alert, for: webView) { [weak self] pressed in
            guard pressed == 0 else { return }
            if NSWorkspace.shared.open(url) { self?.sheets.handedOff += 1 }
        }
    }
}
