import Foundation

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in Downloads/DownloadListTests.swift.

/// One download as its sidebar row shows it.
public struct DownloadItem: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        /// Saving; the fraction done, nil while the size is not known.
        case running(Double?)
        case finished
        case failed(String)
        case cancelled
    }

    public let id: Int
    public var name: String
    public var state: State
    /// Running with no new bytes for `DownloadList.stallAfter` (F9).
    public var stalled = false

    /// The row's second line: "42 %", "…", "done", "failed: <reason>", "cancelled".
    public var stateText: String {
        switch state {
        case .running(let done):
            if stalled { return "stalled" }
            guard let done, done >= 0, done.isFinite else { return "…" }
            return "\(Int((min(done, 1) * 100).rounded(.down))) %"
        case .finished: return "done"
        case .failed(let reason): return "failed: \(reason)"
        case .cancelled: return "cancelled"
        }
    }

    public init(id: Int, name: String, state: State) {
        self.id = id
        self.name = name
        self.state = state
    }
}

/// The downloads of this launch, newest first. The sidebar footer shows every running download (F2: none
/// is hidden; the footer scrolls) and the newest ended ones up to `shown` rows; an older ended row is
/// dropped. Nothing is kept across a quit.
public struct DownloadList: Equatable, Sendable {
    public static let shown = 3
    /// No new bytes for this long: the row reads "stalled" (F9).
    public static let stallAfter: TimeInterval = 60
    public private(set) var items: [DownloadItem] = []
    private var nextId = 1
    private var lastBytes: [Int: Date] = [:]

    public init() {}

    /// A new running row on top; its id.
    @discardableResult
    public mutating func add(_ name: String, at date: Date = Date()) -> Int {
        let id = nextId
        nextId += 1
        items.insert(DownloadItem(id: id, name: name, state: .running(nil)), at: 0)
        lastBytes[id] = date
        items = shownItems
        return id
    }

    public mutating func set(_ id: Int, _ state: DownloadItem.State) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].state = state
        if case .running = state {} else { items[index].stalled = false }
    }

    public mutating func rename(_ id: Int, _ name: String) {
        if let index = items.firstIndex(where: { $0.id == id }) { items[index].name = name }
    }

    /// New bytes: the fraction done (nil: size unknown); a stalled row runs again.
    public mutating func progressed(_ id: Int, _ done: Double?, at date: Date) {
        guard let index = items.firstIndex(where: { $0.id == id }), case .running = items[index].state else { return }
        items[index].state = .running(done)
        items[index].stalled = false
        lastBytes[id] = date
    }

    /// Mark the running rows with no new bytes for `stallAfter`; whether a row changed.
    public mutating func markStalls(now: Date) -> Bool {
        var changed = false
        for index in items.indices {
            guard case .running = items[index].state, !items[index].stalled,
                  let last = lastBytes[items[index].id], now.timeIntervalSince(last) >= Self.stallAfter
            else { continue }
            items[index].stalled = true
            changed = true
        }
        return changed
    }

    /// Whether any download still runs (the app checks for stalls only then).
    public var hasRunning: Bool { items.contains { if case .running = $0.state { return true } else { return false } } }

    public func item(_ id: Int) -> DownloadItem? { items.first { $0.id == id } }

    /// The rows the footer shows, top to bottom: every running one, and ended ones while there is room.
    public var shownItems: [DownloadItem] {
        let running = items.filter { if case .running = $0.state { return true } else { return false } }.count
        var room = max(0, Self.shown - running)
        return items.filter { item in
            if case .running = item.state { return true }
            guard room > 0 else { return false }
            room -= 1
            return true
        }
    }
}
