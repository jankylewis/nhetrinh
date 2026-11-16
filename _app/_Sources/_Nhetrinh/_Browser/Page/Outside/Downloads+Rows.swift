import AppKit
import NhetrinhCore
import WebKit

/// The footer's rows (every running download has one, F2), progress and stalls (F9), and the gate on a
/// page's downloads without a click (F2): past `DownloadGate.freeUnclicked` the user is asked once.
extension Downloads {
    static let stallCheck: TimeInterval = 5

    /// A click on a finished row: Finder shows the file.
    func reveal(row: Int) -> Bool {
        guard let item = shown(row), item.state == .finished,
              let file = entries.first(where: { $0.id == item.id })?.file,
              NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "") else { return false }
        revealed.append(file.lastPathComponent)
        return true
    }

    func shown(_ row: Int) -> DownloadItem? {
        list.shownItems.indices.contains(row) ? list.shownItems[row] : nil
    }

    func running(row: Int) -> Entry? {
        guard let item = shown(row), case .running = item.state else { return nil }
        return entries.first { $0.id == item.id }
    }

    /// New bytes: the row's percent (redrawn at most 100 times a download) and the time, for stalls.
    func watch(_ entry: Entry) {
        entry.watch = entry.download.progress.observe(\.completedUnitCount) { [weak self] progress, _ in
            let done = progress.totalUnitCount > 0 ? progress.fractionCompleted : nil
            DispatchQueue.main.async {
                guard let self, let item = self.list.item(entry.id),
                      case .running(let shown) = item.state else { return }
                self.list.progressed(entry.id, done, at: Date())
                if item.stalled || shown.map({ Int($0 * 100) }) != done.map({ Int($0 * 100) }) { self.onChange?() }
            }
        }
    }

    /// While a download runs, check for stalls every few seconds; no timer when none runs (idle CPU).
    func watchStalls() {
        guard stallTimer == nil, list.hasRunning else { return }
        let timer = Timer(timeInterval: Self.stallCheck, repeats: true) { [weak self] _ in self?.checkStalls() }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        stallTimer = timer
    }

    func checkStalls(now: Date = Date()) {
        if list.markStalls(now: now) { onChange?() }
        if !list.hasRunning {
            stallTimer?.invalidate()
            stallTimer = nil
        }
    }

    /// May the page `page` start a download? `clicked`: the user clicked or typed in it just now. Past the
    /// free ones `ask` shows the question once; downloads that come meanwhile wait for the same answer.
    func admit(page: String, clicked: Bool, ask: (@escaping (Bool) -> Void) -> Void, then: @escaping (Bool) -> Void) {
        if !clicked, var waiting = asking[page] {
            waiting.append(then)
            asking[page] = waiting
            return
        }
        switch gate.decide(page: page, clicked: clicked) {
        case .go: then(true)
        case .refuse: then(false)
        case .ask:
            asking[page] = [then]
            ask { [weak self] allowed in
                self?.gate.answer(page: page, allowed: allowed)
                (self?.asking.removeValue(forKey: page) ?? []).forEach { $0(allowed) }
            }
        }
    }
}
