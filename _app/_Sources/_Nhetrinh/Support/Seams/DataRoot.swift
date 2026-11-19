import AppKit
import NhetrinhCore
import WebKit

/// P10-PROFILE (D29): the seams of the profile folders. Before a launch, which is every unit test, the root is a
/// folder of this process's own under the temporary folder, Finder is never asked and no WebKit store is
/// cleared: no test reaches the real `Application Support/nhetrinh` or a data store (guard test). `AppDelegate`
/// calls `launch()` first thing at launch, as it sets `Screen.presenter`.
enum DataRoot {
    /// Application Support: a temporary folder until the launch.
    static var support = FileManager.default.temporaryDirectory
        .appendingPathComponent("nhetrinh-unlaunched-\(getpid())", isDirectory: true)
    /// The folder this launch uses, once the migration chose it (P9's old one after a failed migration).
    static var inUse: URL?
    /// Shows a folder in Finder.
    static var reveal: (URL) -> Void = { _ in }
    /// Removes every website data of this profile's store, then calls back.
    static var clearWebData: (@escaping () -> Void) -> Void = { done in done() }

    /// The launched app's real seams.
    static func launch() {
        if let real = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            support = real
        }
        reveal = { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
        clearWebData = { done in
            WebConfig.shared.websiteDataStore.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                         modifiedSince: .distantPast, completionHandler: done)
        }
    }
}
