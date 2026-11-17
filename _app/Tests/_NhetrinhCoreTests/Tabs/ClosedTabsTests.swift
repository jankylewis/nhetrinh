import Foundation
import Testing
@testable import NhetrinhCore

// P2 tests (hubs/product/plan/M1_DAILY_DRIVER.md), red first (P2-PREP-1):
// `ClosedTabs` is a stub, so every case here fails until P2 builds it.

private func closed(_ number: Int) -> ClosedTab {
    let url = URL(string: "https://example.com/\(number)") ?? URL(fileURLWithPath: "/")
    return ClosedTab(url: url, title: "Tab \(number)", index: number % 7)
}

private func pushed(_ count: Int) -> ClosedTabs {
    var tabs = ClosedTabs()
    (1...count).forEach { tabs.push(closed($0)) }
    return tabs
}

@Test(arguments: [1, 2, 5])
func popGivesTheLastClosedFirst(count: Int) {
    var tabs = pushed(count)
    #expect(tabs.count == count)
    let popped = (1...count).map { _ in tabs.pop() }
    #expect(popped == (1...count).reversed().map { Closed.tab(closed($0)) })
}

@Test(arguments: [1, 3, 20])
func popAfterTheLastIsNil(count: Int) {
    var tabs = pushed(count)
    (1...count).forEach { _ in #expect(tabs.pop() != nil) }
    #expect(tabs.pop() == nil)
    #expect(tabs.count == 0)
}

@Test(arguments: [20, 21, 40])
func keepsOnlyTheNewest20(count: Int) {
    var tabs = pushed(count)
    #expect(ClosedTabs.capacity == 20)
    #expect(tabs.count == 20)
    let popped = (1...20).map { _ in tabs.pop() }
    #expect(popped == ((count - 19)...count).reversed().map { Closed.tab(closed($0)) })
    #expect(tabs.pop() == nil)
}

@Test(arguments: [1, 4])
func pushAfterPopKeepsTheOrder(count: Int) {
    var tabs = pushed(count)
    let last = tabs.pop()
    tabs.push(closed(99))
    #expect(last == .tab(closed(count)))
    #expect(tabs.pop() == .tab(closed(99)))
    #expect(tabs.count == count - 1)
}

/// P8-GROUPS-1: a closed group is kept as one entry, between tabs, in the order closed.
@Test func aClosedGroupIsOneEntry() {
    var tabs = pushed(1)
    let group = ClosedGroup(group: TabFolder(name: "PRs", tabs: [treeTab("a")]), path: TabPath([0, 1]),
                            groups: ["MBing"])
    tabs.push(.group(group))
    tabs.push(closed(2))
    #expect(tabs.count == 3 && tabs.pop() == .tab(closed(2)) && tabs.pop() == .group(group))
}
