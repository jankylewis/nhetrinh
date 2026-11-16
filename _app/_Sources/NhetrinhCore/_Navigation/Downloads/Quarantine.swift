import CoreServices
import Foundation

// P5-FIX-1 (ruling on nhetrinh_wt/REVIEW_P5.md, F5); tests in Downloads/DownloadGuardTests.swift.

/// macOS's quarantine on a downloaded file (`com.apple.quarantine`), as Safari sets it: Gatekeeper then
/// checks an app or a script from the file before it first runs, and Finder says where it came from.
public enum Quarantine {
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
    }
}
