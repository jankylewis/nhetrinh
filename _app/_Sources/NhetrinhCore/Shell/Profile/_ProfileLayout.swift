import Foundation

/// P10-PROFILE (D29): one folder per profile under `<Application Support>/nhetrinh/`: `Default/` is the
/// headmate's own profile (no `NHT_PROFILE`), `<name>/` any other (`NHT_PROFILE=<name>`, e.g. `readback/`).
/// HARD RULE: `Default` keeps WebKit's default data store and P9's Keychain service, so its cookies and kept
/// sign-ins are found again; only other profiles use a store of their own (`Profile.identifier`).
public struct ProfileLayout: Equatable {
    public static let appFolder = "nhetrinh"
    public static let defaultName = "Default"
    /// Where P1 to P9 kept a named profile: `profiles/<identifier>/` (`ProfileMigration` moves it).
    public static let legacyProfiles = "profiles"
    public static let maxNameLength = 64

    /// `<Application Support>/nhetrinh`.
    public let root: URL
    public let name: String
    public let isDefault: Bool

    /// nil when `profile` is refused (`refusal`): such a launch keeps nothing, never another profile's data.
    public init?(applicationSupport: URL, profile: String?) {
        root = applicationSupport.appendingPathComponent(Self.appFolder, isDirectory: true)
        let given = profile ?? ""
        isDefault = given.isEmpty
        name = isDefault ? Self.defaultName : given
        if !isDefault, Self.refusal(given) != nil { return nil }
    }

    /// This profile's folder: `Default/` or `<name>/`, always a direct child of `root`.
    public var folder: URL { root.appendingPathComponent(name, isDirectory: true) }

    /// Where P1 to P9 kept this profile: the root itself for `Default`, `profiles/<identifier>/` for another.
    public var legacyFolder: URL {
        guard !isDefault else { return root }
        return root.appendingPathComponent(Self.legacyProfiles, isDirectory: true)
            .appendingPathComponent(Profile.identifier(for: name).uuidString, isDirectory: true)
    }

    /// `Default`: WebKit's default store (every cookie and sign-in the headmate has). Another: its own.
    public var webStore: WebStore { isDefault ? .standard : .identifier(Profile.identifier(for: name)) }

    /// P9's service: `...signins.default` for `Default`, `...signins.<name>` for another (unchanged).
    public var keychainService: String { SignIns.service(profile: isDefault ? nil : name) }

    /// What `profile.json` records.
    public var info: ProfileInfo {
        ProfileInfo(version: ProfileInfo.current, name: name, webStore: webStore.text, keychainService: keychainService)
    }

    /// Why `name` cannot be a profile, or nil. `default` in any case would share `Default`'s folder (a disk
    /// that ignores case) and its Keychain item; `profiles` and P9's root files would collide with old files.
    public static func refusal(_ name: String) -> String? {
        let lower = name.lowercased()
        if lower == defaultName.lowercased() { return "the name of the default profile" }
        if lower == legacyProfiles || ProfileMigration.rootFiles.contains(lower) { return "a name nhetrinh uses" }
        if name.count > maxNameLength { return "longer than \(maxNameLength) characters" }
        if name.hasPrefix(".") || name != name.trimmingCharacters(in: .whitespaces) {
            return "starts with a dot, or starts or ends with a space"
        }
        let bad = CharacterSet(charactersIn: "/:\\").union(.controlCharacters).union(.newlines)
        if name.unicodeScalars.contains(where: bad.contains) { return "holds / : \\ or a control character" }
        return nil
    }
}

/// The WebKit data store of a profile.
public enum WebStore: Equatable {
    /// `WKWebsiteDataStore.default()`: `Default` only.
    case standard
    /// `WKWebsiteDataStore(forIdentifier:)`.
    case identifier(UUID)

    /// As `profile.json` holds it: `default` or the identifier.
    public var text: String {
        switch self {
        case .standard: return "default"
        case .identifier(let id): return id.uuidString
        }
    }
}
