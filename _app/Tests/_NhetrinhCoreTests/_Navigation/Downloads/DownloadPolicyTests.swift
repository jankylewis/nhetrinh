import Foundation
import Testing
@testable import NhetrinhCore

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md), red first: `DownloadPolicy.decide` was a stub that
// showed everything, so every download case here failed.

/// The table: type x WebKit can show it x Content-Disposition.
@Test(arguments: [
    ("text/html", true, nil, DownloadPolicy.Decision.show),
    ("text/html", true, "inline", .show),
    ("text/html", true, "attachment", .download),
    ("text/html", true, "attachment; filename=\"a.html\"", .download),
    ("application/pdf", true, nil, .show),
    ("application/pdf", true, "Attachment; filename=a.pdf", .download),
    ("application/pdf", true, "  attachment", .download),
    ("application/zip", false, nil, .download),
    ("application/zip", false, "inline", .download),
    ("application/zip", false, "attachment", .download),
    ("application/octet-stream", true, nil, .download),
    ("Application/Octet-Stream", false, nil, .download),
    ("application/x-download", true, "inline", .download),
    ("application/force-download", true, nil, .download),
    (nil, false, nil, .download),
    (nil, true, nil, .show),
    ("image/png", true, "inline; filename=attachment.png", .show),
    ("image/png", true, "attachments", .show),
] as [(String?, Bool, String?, DownloadPolicy.Decision)])
func decidesShowOrDownload(type: String?, canShow: Bool, disposition: String?, expected: DownloadPolicy.Decision) {
    #expect(DownloadPolicy.decide(type: type, canShow: canShow, disposition: disposition) == expected)
}
