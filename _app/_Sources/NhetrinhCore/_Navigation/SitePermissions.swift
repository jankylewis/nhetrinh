// P3 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in SitePermissionsTests.swift.

/// What a page asks to use.
public enum MediaKind: String, Sendable {
    case camera
    case microphone
    case cameraAndMicrophone = "camera and microphone"
}

/// Camera and microphone answers, per site and kind, kept until the app quits: a site is asked once per
/// launch, and never for what another site was allowed. A site is an origin: scheme, host and port
/// (`site(scheme:host:port:)`), so `http://a.test` and `https://a.test:8443` are each asked (P3-FIX-1).
public struct SitePermissions {
    private var answers: [String: Bool] = [:]

    public init() {}

    /// The kept answer; nil when this site has not been asked for this kind.
    public func decision(site: String, kind: MediaKind) -> Bool? {
        answers[site + " " + kind.rawValue]
    }

    public mutating func record(_ allowed: Bool, site: String, kind: MediaKind) {
        answers[site + " " + kind.rawValue] = allowed
    }

    /// The site of an origin as WebKit gives it (`WKSecurityOrigin`: protocol, host, port; port 0 is the
    /// scheme's default). Case does not matter; a default port written out is the same site.
    public static func site(scheme: String, host: String, port: Int) -> String {
        let scheme = scheme.lowercased()
        let defaults = ["http": 80, "https": 443]
        let port = port == 0 ? defaults[scheme] ?? 0 : port
        return "\(scheme)://\(host.lowercased()):\(port)"
    }

    /// The question the sheet asks.
    public static func question(host: String, kind: MediaKind) -> String {
        "Allow \(host.isEmpty ? "this page" : host) to use your \(kind.rawValue)?"
    }
}
