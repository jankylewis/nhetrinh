// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in SitePermissionsTests.swift.

/// What a page asks to use.
public enum MediaKind: String, Sendable {
    case camera
    case microphone
    case cameraAndMicrophone = "camera and microphone"
}

/// Camera and microphone answers, per site (host) and kind, kept until the app quits: a site is
/// asked once per launch, and never for what another site was allowed.
public struct SitePermissions {
    private var answers: [String: Bool] = [:]

    public init() {}

    /// The kept answer; nil when this site has not been asked for this kind.
    public func decision(host: String, kind: MediaKind) -> Bool? {
        answers[Self.key(host, kind)]
    }

    public mutating func record(_ allowed: Bool, host: String, kind: MediaKind) {
        answers[Self.key(host, kind)] = allowed
    }

    /// The question the sheet asks.
    public static func question(host: String, kind: MediaKind) -> String {
        "Allow \(host.isEmpty ? "this page" : host) to use your \(kind.rawValue)?"
    }

    private static func key(_ host: String, _ kind: MediaKind) -> String {
        host.lowercased() + " " + kind.rawValue
    }
}
