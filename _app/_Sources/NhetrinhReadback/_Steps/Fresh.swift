import Foundation

/// A step never holds an accessibility element across a change of the app (NT-GAT-006): the
/// sidebar reloads its rows on every title or address change, and a row read before that is an
/// invalid element (-25202). A step looks the element up again right before it acts, by its index
/// in a fresh read, and acts once more after a short wait when the element went stale meanwhile.
enum Fresh {
    /// How long to wait before the one retry: the reload of the sidebar is done by then.
    static let retryWait: TimeInterval = 0.3

    /// The index of the row `fromEnd` places above the last (0 is the last) among `count` rows;
    /// nil when there are not enough rows.
    static func rowIndex(fromEnd: Int, count: Int) -> Int? {
        guard fromEnd >= 0, fromEnd < count else { return nil }
        return count - 1 - fromEnd
    }

    /// Run `act`, which must look its element up itself. When it cannot drive the app, wait and
    /// run it once more; a second failure says that it came after a fresh lookup. A step that ran
    /// and saw the app wrong (`StepError.fail`) is not retried.
    static func retryingOnce<T>(wait: TimeInterval = retryWait,
                                sleep: (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) },
                                _ act: () throws -> T) throws -> T {
        do {
            return try act()
        } catch StepError.cannotDrive {
            sleep(wait)
            do {
                return try act()
            } catch StepError.cannotDrive(let why) {
                throw StepError.cannotDrive("\(why), again after a fresh lookup")
            }
        }
    }
}
