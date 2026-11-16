import Foundation

// P2 favicons (hubs/product/plan/M1_DAILY_DRIVER.md); tests in IconCacheTests.swift.

/// A memory cache that keeps at most `capacity` values; past it, the least recently used goes.
/// Small on purpose (200 icons): a linear search of the order costs nothing at that size.
public struct IconCache<Key: Hashable, Value> {
    public let capacity: Int
    private var values: [Key: Value] = [:]
    /// Least recently used first.
    private var order: [Key] = []

    public init(capacity: Int) {
        self.capacity = capacity
    }

    public var count: Int { values.count }

    /// Read without changing the order; a set marks the value as just used.
    public subscript(key: Key) -> Value? {
        get { values[key] }
        set {
            order.removeAll { $0 == key }
            values[key] = nil
            guard let newValue, capacity > 0 else { return }
            values[key] = newValue
            order.append(key)
            while order.count > capacity { values[order.removeFirst()] = nil }
        }
    }

    /// Read, and mark the value as just used.
    public mutating func touch(_ key: Key) -> Value? {
        guard let value = values[key] else { return nil }
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }
}
