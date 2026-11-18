import Foundation

// P5-FIX-1 (ruling on nhetrinh_wt/REVIEW_P5.md, F2); tests in Downloads/DownloadGuardTests.swift.

/// Downloads a page starts without a click of the user (`<a download>` clicked by a script, a redirect
/// to an attachment). Each page gets `freeUnclicked` of them; past that the user is asked once, and the
/// answer holds for that page. A download soon after a click or a key in the page is the user's.
public struct DownloadGate: Equatable, Sendable {
    public enum Decision: Equatable, Sendable { case go, ask, refuse }

    public static let freeUnclicked = 5
    /// A mouse or key event in the page this recently makes a download the user's.
    public static let clickWindow: TimeInterval = 5

    private var unclicked: [String: Int] = [:]
    private var answers: [String: Bool] = [:]

    public init() {}

    public static func isClicked(lastInput: Date?, now: Date) -> Bool {
        guard let lastInput else { return false }
        let since = now.timeIntervalSince(lastInput)
        return since >= 0 && since <= clickWindow
    }

    /// `page`: the asking page (the app's key: its web view and host). `.ask` until `answer` is given.
    public mutating func decide(page: String, clicked: Bool) -> Decision {
        if clicked { return .go }
        if let allowed = answers[page] { return allowed ? .go : .refuse }
        let count = unclicked[page, default: 0] + 1
        unclicked[page] = count
        return count > Self.freeUnclicked ? .ask : .go
    }

    public mutating func answer(page: String, allowed: Bool) {
        answers[page] = allowed
    }
}
