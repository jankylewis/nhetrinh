import AppKit
import NhetrinhCore
import WebKit

/// P4 (hubs/product/plan/M2_REAL_SITES_WORK.md): the find bar under the toolbar, and page zoom kept per
/// host. WebKit's find answers found or not found only, so the bar shows no match count.
extension BrowserWindowController {
    /// Edit > Find > Find… (⌘F): the bar shows, its field takes the focus with its text selected.
    @objc func showFind(_ sender: Any?) {
        findBar.isHidden = false
        findBarHeight?.constant = FindBar.height
        window?.makeFirstResponder(findBar.field)
        findBar.field.selectText(nil)
    }

    @objc func findNext(_ sender: Any?) { findAgain(backwards: false) }
    @objc func findPrevious(_ sender: Any?) { findAgain(backwards: true) }

    private func findAgain(backwards: Bool) {
        if findBar.isHidden { return showFind(nil) }
        find(findBar.field.stringValue, backwards: backwards)
    }

    func find(_ text: String, backwards: Bool) {
        guard let webView = current, !text.isEmpty else { return findBar.show(found: nil) }
        let configuration = WKFindConfiguration()
        configuration.backwards = backwards
        configuration.wraps = true
        webView.find(text, configuration: configuration) { [weak self] result in
            self?.findBar.show(found: result.matchFound)
        }
    }

    /// Esc or the bar's Close: the bar goes and the page has the focus again.
    func closeFind() {
        findBar.isHidden = true
        findBarHeight?.constant = 0
        findBar.show(found: nil)
        window?.makeFirstResponder(current)
    }

    @objc func zoomIn(_ sender: Any?) { setZoom(Zoom.zoomIn(from: currentZoom)) }
    @objc func zoomOut(_ sender: Any?) { setZoom(Zoom.zoomOut(from: currentZoom)) }
    @objc func actualSize(_ sender: Any?) { setZoom(1) }

    var currentZoom: Double { Double(current?.pageZoom ?? 1) }

    /// The selected page at `level`, kept for its host (100 % keeps no entry); every loaded tab of that
    /// host follows (F8, through `applyPrefs`). A page with no host is zoomed alone, not kept.
    private func setZoom(_ level: Double) {
        guard let webView = current else { return }
        webView.pageZoom = CGFloat(level)
        if let key = (webView.url ?? tabs[selected].url).flatMap(Zoom.hostKey) {
            updatePrefs { $0.zoom[key] = abs(level - 1) < 0.001 ? nil : level }
        }
        toolbar.showZoom(Zoom.badge(level))
    }

    /// A page of another host committed: its own kept level, or 100 %.
    func applySavedZoom(to webView: WKWebView) {
        guard let key = webView.url.flatMap(Zoom.hostKey) else { return apply(1, to: webView) }
        apply(prefs.zoom[key] ?? 1, to: webView)
    }

    /// Every loaded tab with a host at its host's kept level: after a zoom (F8) and after Clear All (F6).
    func applyZoomToLoadedTabs() {
        for tab in tabs {
            guard let webView = tab.webView, let key = (webView.url ?? tab.url).flatMap(Zoom.hostKey) else { continue }
            apply(prefs.zoom[key] ?? 1, to: webView)
        }
    }

    private func apply(_ level: Double, to webView: WKWebView) {
        if abs(Double(webView.pageZoom) - level) > 0.001 { webView.pageZoom = CGFloat(level) }
        if webView === current { toolbar.showZoom(Zoom.badge(level)) }
    }
}
