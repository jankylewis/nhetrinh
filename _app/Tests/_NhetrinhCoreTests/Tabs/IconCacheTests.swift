import Testing
@testable import NhetrinhCore

// P2: the favicon memory cache keeps at most `capacity` icons, the least recently used goes first.

private func filled(_ count: Int, capacity: Int) -> IconCache<Int, String> {
    var cache = IconCache<Int, String>(capacity: capacity)
    (1...count).forEach { cache[$0] = "icon \($0)" }
    return cache
}

@Test(arguments: [1, 5, 200])
func keepsWhatFits(count: Int) {
    let cache = filled(count, capacity: 200)
    #expect(cache.count == count)
    #expect((1...count).allSatisfy { cache[$0] == "icon \($0)" })
}

@Test(arguments: [201, 250, 400])
func dropsTheOldestPastTheCapacity(count: Int) {
    let cache = filled(count, capacity: 200)
    #expect(cache.count == 200)
    #expect(cache[count - 200] == nil)
    #expect(cache[count - 199] == "icon \(count - 199)")
    #expect(cache[count] == "icon \(count)")
}

@Test(arguments: [3, 10])
func aReadKeepsAnIcon(capacity: Int) {
    var cache = filled(capacity, capacity: capacity)
    _ = cache.touch(1)
    cache[capacity + 1] = "new"
    #expect(cache[1] == "icon 1")
    #expect(cache[2] == nil)
}

@Test(arguments: [1, 4])
func setAgainReplacesWithoutGrowing(count: Int) {
    var cache = filled(count, capacity: 10)
    cache[1] = "again"
    #expect(cache.count == count)
    #expect(cache[1] == "again")
}

@Test(arguments: [0, -3])
func noCapacityKeepsNothing(capacity: Int) {
    var cache = IconCache<Int, String>(capacity: capacity)
    cache[1] = "icon"
    #expect(cache.count == 0 && cache[1] == nil)
}
