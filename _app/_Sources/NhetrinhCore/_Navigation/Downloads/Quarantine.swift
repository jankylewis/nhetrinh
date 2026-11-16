import CoreServices
import Foundation

// P5-FIX-1 (ruling on nhetrinh_wt/REVIEW_P5.md, F5); tests in Downloads/DownloadGuardTests.swift.

/// macOS's quarantine on a downloaded file (`com.apple.quarantine`), as Safari sets it: Gatekeeper then
/// checks an app or a script from the file before it first runs. Finder's "Where from" is a second
/// attribute (`kMDItemWhereFroms`): on this macOS the quarantine keeps its type and agent but drops the
/// URLs given to it (P5-FIX-2, NT-NAV-013), so both are written.
public enum Quarantine {
    /// Finder's "Where from" (P5-FIX-2): Spotlight's attribute, a binary property list of URL strings.
    public static let whereFromsName = "com.apple.metadata:kMDItemWhereFroms"

    /// `source`: the file's own URL; `page`: the page it was downloaded from.
    public static func mark(_ file: URL, source: URL?, page: URL?) throws {
        var properties: [String: Any] = [
            kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload as String,
            kLSQuarantineAgentNameKey as String: "nhetrinh",
        ]
        if let source { properties[kLSQuarantineDataURLKey as String] = source }
        if let page { properties[kLSQuarantineOriginURLKey as String] = page }
        var values = URLResourceValues()
        values.quarantineProperties = properties
        var target = file
        try target.setResourceValues(values)
        try setWhereFroms(file, [source, page].compactMap { $0 })
    }

    /// `urls` as Safari writes them: the file's URL, then the page's; no user name or password; each once.
    static func setWhereFroms(_ file: URL, _ urls: [URL]) throws {
        var seen: [String] = []
        for url in urls.map(withoutCredentials) where !seen.contains(url) { seen.append(url) }
        guard !seen.isEmpty else { return }
        let data = try PropertyListSerialization.data(fromPropertyList: seen, format: .binary, options: 0)
        let written = data.withUnsafeBytes { setxattr(file.path, whereFromsName, $0.baseAddress, data.count, 0, 0) }
        guard written == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
    }

    private static func withoutCredentials(_ url: URL) -> String {
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url.absoluteString }
        parts.user = nil
        parts.password = nil
        return parts.url?.absoluteString ?? url.absoluteString
    }
}
