import NhetrinhCore
import WebKit

/// Idle unload: a background tab unused for `unloadAfter` gives its page process back. Before any
/// unload WebKit is asked whether the tab plays media; a playing tab is kept (NT-TAB-001).
extension BrowserWindowController {
    /// NHT_UNLOAD_AFTER_S=<seconds> shortens the limit: the readback sets 5 s for R11 and R12.
    static let unloadOverride: TimeInterval? = {
        ProcessInfo.processInfo.environment["NHT_UNLOAD_AFTER_S"].flatMap(TimeInterval.init).map { max(1, $0) }
    }()

    /// The limit: the override, else the Settings Hub's minutes (P4, `Prefs.idleUnloadMinutes`).
    var unloadAfter: TimeInterval { Self.unloadOverride ?? TimeInterval(prefs.idleUnloadMinutes) * 60 }

    /// Check a fifth of the limit apart: once a minute for 10 min, once a second for 5 s. Called
    /// again when the limit changes: the old timer goes.
    func startIdleUnloading() {
        unloadTimer?.invalidate()
        guard !Bench.loadAll else { return }
        let every = min(60, max(1, unloadAfter / 5))
        unloadTimer = Timer.scheduledTimer(withTimeInterval: every, repeats: true) { [weak self] _ in
            self?.unloadIdleTabs()
        }
    }

    /// Ask WebKit about every tab idle long enough at `pressure` (P6), then unload the ones the policy
    /// still names.
    func unloadIdleTabs(now: Date = Date(), pressure: UnloadPolicy.Pressure = .normal) {
        let idle = UnloadPolicy.tabsToUnload(policyStates(playing: []), selected: selected, now: now,
                                             idleLimit: unloadAfter, pressure: pressure).map { tabs[$0] }
        guard !idle.isEmpty else { return }
        let playing = PlayingTabs()
        let answers = DispatchGroup()
        for tab in idle {
            guard let webView = tab.webView else { continue }
            let id = ObjectIdentifier(tab)
            answers.enter()
            webView.requestMediaPlaybackState { state in  // answered on the main queue
                if state == .playing { playing.ids.insert(id) }
                answers.leave()
            }
        }
        let asked = Set(idle.map(ObjectIdentifier.init))
        answers.notify(queue: .main) { [weak self] in
            self?.unload(asked: asked, playing: playing.ids, pressure: pressure)
        }
    }

    /// The policy again, on the tabs as they are now: a tab selected meanwhile is kept, and a tab
    /// WebKit was not asked about counts as playing (kept until the next check asks).
    private func unload(asked: Set<ObjectIdentifier>, playing: Set<ObjectIdentifier>, pressure: UnloadPolicy.Pressure) {
        let keep = Set(tabs.map(ObjectIdentifier.init)).subtracting(asked).union(playing)
        for tab in tabs where playing.contains(ObjectIdentifier(tab)) {
            Log.web.info("idle unload: a tab plays media; it stays loaded (NT-TAB-001)")
        }
        let indexes = UnloadPolicy.tabsToUnload(policyStates(playing: keep), selected: selected, now: Date(),
                                                idleLimit: unloadAfter, pressure: pressure)
        guard !indexes.isEmpty else { return }
        indexes.forEach { tabs[$0].unload() }
        refreshChrome()
    }

    private func policyStates(playing: Set<ObjectIdentifier>) -> [UnloadPolicy.TabState] {
        tabs.map { tab in
            UnloadPolicy.TabState(lastActive: tab.lastActive, isLoaded: tab.isLoaded,
                                  isPlaying: playing.contains(ObjectIdentifier(tab)), isCapturing: capturing(tab))
        }
    }
}

extension BrowserWindowController {
    /// The page holds the camera or the microphone, on or muted: a call is not cut (F3 ruling).
    func capturing(_ tab: Tab) -> Bool {
        guard let webView = tab.webView else { return false }
        return webView.cameraCaptureState != .none || webView.microphoneCaptureState != .none
    }
}

/// WebKit's answers, collected on the main queue until every asked tab has answered.
private final class PlayingTabs: @unchecked Sendable {
    var ids: Set<ObjectIdentifier> = []
}
