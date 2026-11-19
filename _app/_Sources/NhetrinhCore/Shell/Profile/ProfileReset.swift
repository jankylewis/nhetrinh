import Foundation

/// P10-PROFILE (D29): Settings Hub > Reset profile… empties this profile's folder; the app also deletes its
/// Keychain item and its WebKit store's data. Never another profile: only `layout.folder`, only when it is the
/// folder in use (after a failed migration the old root is in use, and holds other profiles: refused).
public enum ProfileReset {
    /// Kept: what the profile is (`profile.json`) and this run's crash marker (removed at a clean quit).
    public static let kept: Set<String> = [ProfileInfo.fileName, CleanQuitMarker.fileName]

    public enum Refusal: Error, Equatable {
        /// The folder in use is not the profile's own folder.
        case notInUse
    }

    /// The names removed from `layout.folder`; refused when `inUse` is not that folder.
    @discardableResult
    public static func empty(_ layout: ProfileLayout, inUse: URL,
                             remove: (URL) throws -> Void = FileManager.default.removeItem) throws -> [String] {
        let folder = layout.folder.standardizedFileURL
        guard inUse.standardizedFileURL == folder,
              folder.deletingLastPathComponent() == layout.root.standardizedFileURL else { throw Refusal.notInUse }
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        let gone = names.filter { !kept.contains($0) }.sorted()
        for name in gone { try remove(folder.appendingPathComponent(name)) }
        return gone
    }
}
