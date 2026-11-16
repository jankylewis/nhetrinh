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

    /// The row's second line: "42 %", "…", "done", "failed: <reason>", "cancelled".
    public var stateText: String {
        switch state {
        case .running(let done):
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

/// The downloads of this launch, newest first. The sidebar footer shows the first `shown`; an older
/// row that no longer runs is dropped. Nothing is kept across a quit.
public struct DownloadList: Equatable, Sendable {
    public static let shown = 3
    public private(set) var items: [DownloadItem] = []
    private var nextId = 1

    public init() {}

    /// A new running row on top; its id.
    @discardableResult
    public mutating func add(_ name: String) -> Int {
        let id = nextId
        nextId += 1
        items.insert(DownloadItem(id: id, name: name, state: .running(nil)), at: 0)
        items = items.enumerated().filter { index, item in
            if index < Self.shown { return true }
            if case .running = item.state { return true }
            return false
        }.map(\.element)
        return id
    }

    public mutating func set(_ id: Int, _ state: DownloadItem.State) {
        if let index = items.firstIndex(where: { $0.id == id }) { items[index].state = state }
    }

    public mutating func rename(_ id: Int, _ name: String) {
        if let index = items.firstIndex(where: { $0.id == id }) { items[index].name = name }
    }

    public func item(_ id: Int) -> DownloadItem? { items.first { $0.id == id } }

    /// The rows the footer shows, top to bottom.
    public var shownItems: [DownloadItem] { Array(items.prefix(Self.shown)) }
}
