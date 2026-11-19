import NhetrinhCore

/// Put Tab to Idle / Put Other Tabs to Idle (headmate, 2026-11-19): a row's menu sends tabs idle now, as the idle
/// timer does after its minutes (`_IdleUnload.swift`). The tab in view never goes idle: Put Tab to Idle on it first
/// shows the nearest other tab (none: nothing happens); Other Tabs shows the tab clicked. WebKit is asked first;
/// a tab that plays or holds the camera or the microphone stays loaded (NT-TAB-001, F3 ruling).
extension BrowserWindowController {
    func putToIdle(_ index: Int, others: Bool) {
        guard tabs.indices.contains(index) else { return }
        if others {
            if selected != index { select(index) }
        } else if selected == index {
            guard let other = nearestOther(index) else { return }
            select(other)
        }
        let chosen = UnloadPolicy.tabsToIdle(policyStates(playing: []), chosen: index, others: others).map { tabs[$0] }
        guard !chosen.isEmpty else { return }
        askPlaying(chosen) { [weak self] playing in self?.idle(chosen, unless: playing) }
    }

    /// The nearest visible tab above `index`, else below; a hidden one only when no other tab is visible.
    private func nearestOther(_ index: Int) -> Int? {
        let shown = tree.visibleFlatIndexes.filter { $0 != index }
        return shown.last { $0 < index } ?? shown.first { $0 > index } ?? tabs.indices.first { $0 != index }
    }

    /// Unload each of `chosen` still open, not in view, silent and not capturing.
    private func idle(_ chosen: [Tab], unless playing: Set<ObjectIdentifier>) {
        let shown = tabs.indices.contains(selected) ? tabs[selected] : nil
        let open = Set(tabs.map(ObjectIdentifier.init))
        for tab in chosen where open.contains(ObjectIdentifier(tab)) && tab !== shown
            && !playing.contains(ObjectIdentifier(tab)) && !capturing(tab) {
            tab.unload()
        }
        refreshChrome()
    }
}
