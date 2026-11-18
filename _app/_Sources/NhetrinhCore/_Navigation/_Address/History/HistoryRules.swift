import Foundation

// P11-HISTORY (D30); tests in Tests/_NhetrinhCoreTests/_Navigation/_Address/History/HistoryRulesTests.swift.

/// Which finished main-frame pages the history keeps: http and https with a host only (never about:, data:,
/// file:), never the error page, nothing with the switch off. The readback's own pages (a loopback host while
/// the probe is on, D23) are kept only in the readback profile, so R54 can read its own history.
public struct HistoryRules: Equatable, Sendable {
    public static let readbackProfile = "readback"
    public static let loopbackHosts: Set<String> = ["127.0.0.1", "localhost", "::1", "[::1]"]
    public var remember: Bool
    public var probeOn: Bool
    public var profile: String?

    public init(remember: Bool, probeOn: Bool, profile: String?) {
        self.remember = remember
        self.probeOn = probeOn
        self.profile = profile
    }

    /// Whether a finished visit of `url` is kept; `errorPage`: the page shown is nhetrinh's error page.
    public func records(_ url: URL?, errorPage: Bool) -> Bool {
        guard remember, !errorPage, let url, let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host?.lowercased(), !host.isEmpty else { return false }
        if probeOn, Self.loopbackHosts.contains(host), profile != Self.readbackProfile { return false }
        return true
    }
}
