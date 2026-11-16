import AppKit
import WebKit

/// P2 page state in the chrome: reload becomes stop while a page loads, a thin progress line, the
/// site icon in its row. And the readback probe's link menu (R17), shown as a right click shows it.
extension BrowserWindowController {
    /// The toolbar follows the selected tab's loading; only the toolbar, so progress costs no row redraw.
    func refreshLoading() {
        let webView = current
        toolbar.showLoading(webView?.isLoading ?? false, progress: webView?.estimatedProgress ?? 0)
    }

    /// After a page has finished: its icon, into the row of the tab that shows it.
    func findIcon(of webView: WKWebView) {
        favicons.icon(of: webView) { [weak self, weak webView] image in
            guard let self, let webView, let tab = self.tabs.first(where: { $0.webView === webView }),
                  tab.icon !== image else { return }
            tab.icon = image
            self.refreshChrome()
        }
    }

    static let firstLinkCenter = """
        (() => { const a = document.querySelector('a[href]'); if (!a) return null
          const r = a.getBoundingClientRect(); return [r.left + r.width / 2, r.top + r.height / 2] })()
        """

    /// The probe's R17: a right click on the first link of the selected page, in this app only (no
    /// system event, D18); `item` is pressed once WebKit shows the menu. The answer comes before.
    func showLinkMenu(pressing item: String) -> String? {
        guard let webView = current as? BrowserWebView, let window else { return "no page is shown" }
        webView.evaluateJavaScript(Self.firstLinkCenter) { [weak webView] result, _ in
            guard let webView, let center = result as? [Double], center.count == 2 else {
                return Log.app.error("probe: the page has no link to show a menu on")
            }
            let y = webView.isFlipped ? center[1] : webView.bounds.height - center[1]
            let point = webView.convert(NSPoint(x: center[0], y: y), to: nil)
            webView.pressOnOpen = item
            for type in [NSEvent.EventType.rightMouseDown, .rightMouseUp] {
                guard let event = NSEvent.mouseEvent(with: type, location: point, modifierFlags: [],
                                                     timestamp: ProcessInfo.processInfo.systemUptime,
                                                     windowNumber: window.windowNumber, context: nil,
                                                     eventNumber: 0, clickCount: 1, pressure: 1) else { continue }
                type == .rightMouseDown ? webView.rightMouseDown(with: event) : webView.rightMouseUp(with: event)
            }
        }
        return nil
    }
}
