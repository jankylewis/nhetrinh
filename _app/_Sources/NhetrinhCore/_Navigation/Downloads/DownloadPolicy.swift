import Foundation

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in Downloads/DownloadPolicyTests.swift.

/// Whether a response is shown in the tab or saved as a download. `<a download>` is decided by
/// WebKit's own flag on the link, before any response.
public enum DownloadPolicy {
    public enum Decision: Equatable, Sendable { case show, download }

    /// Types a server sends to force a download, even where WebKit could show them.
    static let forcing: Set<String> = ["application/octet-stream", "application/force-download",
                                       "application/x-download"]

    /// `type`: the response's MIME type; `canShow`: WebKit can show it; `disposition`: the
    /// `Content-Disposition` header. An attachment or a forcing type downloads; else what WebKit
    /// can show is shown and the rest downloads.
    public static func decide(type: String?, canShow: Bool, disposition: String?) -> Decision {
        let kind = disposition?.split(separator: ";").first?.trimmingCharacters(in: .whitespaces).lowercased()
        if kind == "attachment" || forcing.contains(type?.lowercased() ?? "") { return .download }
        return canShow ? .show : .download
    }
}
