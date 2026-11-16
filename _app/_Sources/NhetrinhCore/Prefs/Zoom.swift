import Foundation

/// Page zoom (P4): View > Zoom In / Zoom Out walk these steps, 50 % to 300 %, clamped at both ends.
/// The level is kept per host: lower case, the port ignored.
public enum Zoom {
    public static let steps: [Double] = [0.5, 0.67, 0.75, 0.8, 0.9, 1.0, 1.1, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
    static let nearlySame = 0.001

    public static func clamp(_ level: Double) -> Double {
        guard level.isFinite else { return 1 }
        return min(steps[steps.count - 1], max(steps[0], level))
    }

    /// The first step above `level` (a pinch may leave a level between steps); the top stays.
    public static func zoomIn(from level: Double) -> Double {
        steps.first { $0 > level + nearlySame } ?? steps[steps.count - 1]
    }

    /// The last step below `level`; the bottom stays.
    public static func zoomOut(from level: Double) -> Double {
        steps.last { $0 < level - nearlySame } ?? steps[0]
    }

    /// The key a level is kept under; nil for a page with no host (about:, file:).
    public static func hostKey(_ url: URL) -> String? {
        guard let host = url.host?.lowercased(), !host.isEmpty else { return nil }
        return host
    }

    /// The address bar's badge: "125 %"; nil at 100 %.
    public static func badge(_ level: Double) -> String? {
        abs(level - 1) < nearlySame ? nil : "\(Int((level * 100).rounded())) %"
    }
}
