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
        decisionHandler(decision == .download && response.isForMainFrame ? .download : .allow)
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

    /// Links from other apps: each `http`/`https` URL opens as a new tab at the end, selected.
    func openIncoming(_ urls: [URL]) {
        for url in urls where ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            tree.insert(Tab(url: url), atFlat: tabs.count)  // the root's end; the folders stay (P7)
            select(tabs.count - 1)
        }
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
