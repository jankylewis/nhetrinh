import AppKit
import NhetrinhCore
import WebKit

/// P5: what comes in from outside the page and goes out of it: a response saved as a download
/// (`DownloadPolicy`, `Downloads`), and a link another app hands to nhetrinh (Info.plist declares
/// `http` and `https`), opened as a new tab. The default browser is never changed by the app.
extension BrowserWindowController {
    /// A response WebKit is about to show: shown, or saved as a download. Only the page itself
    /// downloads: a frame inside it never starts one by its response.
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let disposition = (response.response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Disposition")
        let decision = DownloadPolicy.decide(type: response.response.mimeType, canShow: response.canShowMIMEType,
                                             disposition: disposition)
        guard decision == .download, response.isForMainFrame else { return decisionHandler(.allow) }
        admitDownload(from: webView) { decisionHandler($0 ? .download : .cancel) }
    }

    /// F2: a download the page starts without the user's click or key counts; past 5 a sheet asks, once
    /// for the page (its web view and host). Closing the tab while asked answers no.
    func admitDownload(from webView: WKWebView, then: @escaping (Bool) -> Void) {
        let host = webView.url?.host ?? "this page"
        let page = "\(ObjectIdentifier(webView).hashValue) \(host)"
        let clicked = DownloadGate.isClicked(lastInput: (webView as? BrowserWebView)?.lastInput, now: Date())
        downloads.admit(page: page, clicked: clicked, ask: { [weak self, weak webView] done in
            let alert = NSAlert()
            alert.messageText = "\(host) wants to download more files"
            alert.informativeText = "It started \(DownloadGate.freeUnclicked) downloads without a click. Allow more?"
            alert.addButton(withTitle: "Allow")
            alert.addButton(withTitle: "Don't Allow")
            guard let self else { return done(false) }
            self.ask(alert, for: webView) { done($0 == 0) }
        }, then: then)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        downloads.adopt(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        downloads.adopt(download)
    }

    /// The sidebar footer, in step with the downloads.
    func refreshDownloads() {
        sidebar.downloads.show(downloads.list.shownItems)
    }

    /// Links from other apps: each `http`/`https` URL opens as a new tab at the end; the last is selected.
    func openIncoming(_ urls: [URL]) {
        let web = urls.filter { ["http", "https"].contains($0.scheme?.lowercased() ?? "") }
        guard !web.isEmpty else { return }
        web.forEach { tabs.append(Tab(url: $0)) }  // F3: added unloaded; only the last is shown and loads
        select(tabs.count - 1)
    }

    func wireDownloads() {
        downloads.onChange = { [weak self] in self?.refreshDownloads() }
        sidebar.downloads.onCancel = { [weak self] row in _ = self?.downloads.cancel(row: row) }
        sidebar.downloads.onReveal = { [weak self] row in _ = self?.downloads.reveal(row: row) }
    }

    /// The probe's `download`: a row's Cancel pressed, or the row clicked ("Show in Finder"), in the footer.
    /// What followed is read in the state (`downloadStates`, `revealed`).
    func pressDownload(row: Int, item: String) -> ProbeResponse {
        guard let shown = downloads.shown(row) else { return .failed("the footer has no download row \(row)") }
        let ready = item == "Cancel" ? shown.stateText != "done" : shown.state == .finished
        guard ready, sidebar.downloads.press(row: row, item: item) else {
            return .failed("download row \(row) (\(shown.stateText)) has no \(item)")
        }
        return .done
    }

    func readDownloads(into state: inout ProbeState) {
        state.downloads = downloads.list.shownItems.map(\.name)
        state.downloadStates = downloads.list.shownItems.map(\.stateText)
        state.revealed = downloads.revealed
    }
}
