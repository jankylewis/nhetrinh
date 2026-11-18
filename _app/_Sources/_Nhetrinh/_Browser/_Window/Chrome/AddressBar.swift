import AppKit
import NhetrinhCore
import WebKit

/// P11-HISTORY (D30): this launch's history. The store (`history.sqlite` in the profile's folder; today the
/// session's) opens at its first use; none without a folder (a measurement run). It remembers which tabs the
/// user typed into and which loads are the error page, until their page finishes.
final class HistoryKeeper {
    var folder: URL?
    var probeOn = false
    var profile: String?
    /// Tabs whose next finished page was typed or picked in the address bar (a closed tab drops out).
    let typedTabs = NSHashTable<Tab>.weakObjects()
    /// The error page's loads still under way (`showErrorPage`), never kept.
    var errorLoads: [WKNavigation] = []
    private var opened: HistoryStore?
    private var failed = false

    /// The store, opened once; nil without a folder or after a failed open (logged once).
    var store: HistoryStore? {
        if let opened { return opened }
        guard let folder, !failed else { return nil }
        do {
            opened = try HistoryStore(folder: folder)
        } catch {
            failed = true
            Log.app.error("history: the store could not open: \(String(describing: error), privacy: .public)")
        }
        return opened
    }
}

/// The address bar's history: a finished page is kept (`HistoryRules`), the typed text asks for rows (the store's
/// and the open tabs'), a row opens or selects its tab, ⇧⌫ removes it, Clear All empties the store.
extension BrowserWindowController {
    /// At launch: where the history lives (nil: nowhere) and whether this is a readback run (D23).
    func keepHistory(in folder: URL?, env: [String: String] = ProcessInfo.processInfo.environment) {
        history.folder = folder
        history.probeOn = ProbePath.isOn(env)
        history.profile = env["NHT_PROFILE"]
        let list = toolbar.suggestions
        list.onTyping = { [weak self] text in self?.suggest(for: text) }
        list.onOpen = { [weak self] row in self?.open(row) }
        list.onRemove = { [weak self] row in self?.remove(row) }
    }

    /// A main-frame page finished in `webView` (`didFinish`): kept when the rules allow it.
    func recordVisit(in webView: WKWebView, navigation: WKNavigation?) {
        let errorPage = history.errorLoads.contains { $0 === navigation }
        history.errorLoads.removeAll { $0 === navigation }
        guard let tab = tabs.first(where: { $0.webView === webView }) else { return }
        keepVisit(of: tab, url: webView.url, title: webView.title ?? "", errorPage: errorPage)
    }

    /// `tab` finished `url`: kept when the rules allow it, as typed when the user typed or picked it.
    func keepVisit(of tab: Tab, url: URL?, title: String, errorPage: Bool, at date: Date = Date()) {
        let typed = history.typedTabs.contains(tab)
        history.typedTabs.remove(tab)
        let rules = HistoryRules(remember: prefs.rememberHistory, probeOn: history.probeOn, profile: history.profile)
        guard rules.records(url, errorPage: errorPage), let url = url?.absoluteString else { return }
        do {
            try history.store?.record(url: url, title: title, typed: typed, at: date)
        } catch {
            Log.app.error("history: a visit was not kept: \(String(describing: error), privacy: .public)")
        }
    }

    /// The error page's load: never kept (`LoadFailure`).
    func errorPageLoads(_ navigation: WKNavigation?) {
        guard let navigation else { return }
        history.errorLoads = Array((history.errorLoads + [navigation]).suffix(8))
    }

    /// The selected tab's next finished page was typed or picked in the address bar.
    func markTyped() {
        if tabs.indices.contains(selected) { history.typedTabs.add(tabs[selected]) }
    }

    /// The rows for `typed`: the store's (the switch on) and the open tabs', at most 8.
    func suggest(for typed: String) {
        var kept: [HistoryEntry] = []
        if prefs.rememberHistory, !typed.trimmingCharacters(in: .whitespaces).isEmpty {
            kept = (try? history.store?.suggestions(for: typed, now: Date())) ?? []
        }
        let open = tabs.map { OpenTab(url: $0.url?.absoluteString ?? "", title: $0.title) }
        let rows = HistoryMatch.suggestions(history: kept, tabs: open, typed: typed)
        toolbar.suggestions.show(rows, icons: rows.map(icon(for:)))
    }

    /// A row's icon: its tab's, else one already fetched for its site; nil (the globe) otherwise. Nothing is fetched.
    private func icon(for row: Suggestion) -> NSImage? {
        if let index = row.tab, tabs.indices.contains(index), let icon = tabs[index].icon { return icon }
        guard let page = URL(string: row.url), let host = page.host else { return nil }
        if let icon = tabs.first(where: { $0.url?.host == host && $0.icon != nil })?.icon { return icon }
        return FaviconURL.resolve(href: nil, page: page).flatMap { favicons.cache[$0] }
    }

    /// A row opened: its tab selected ("Switch to tab"), else its page in the selected tab, as typed.
    func open(_ row: Suggestion) {
        if let index = row.tab, tabs.indices.contains(index) {
            select(index)
            window?.makeFirstResponder(current)
            return
        }
        toolbar.address.stringValue = row.url
        navigate(row.url)
    }

    /// ⇧⌫: the row's page leaves the history; the rows are asked again.
    func remove(_ row: Suggestion) {
        do {
            try history.store?.remove(url: row.url)
        } catch {
            Log.app.error("history: a page was not removed: \(String(describing: error), privacy: .public)")
        }
        suggest(for: toolbar.address.stringValue)
    }

    /// Clear All: every kept page goes.
    func forgetHistory() {
        do {
            try history.store?.clear()
        } catch {
            Log.app.error("history: not cleared: \(String(describing: error), privacy: .public)")
        }
    }
}
