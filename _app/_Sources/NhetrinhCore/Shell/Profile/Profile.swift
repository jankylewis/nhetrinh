import CryptoKit
import Foundation

/// A named browsing profile: its own cookies, cache and site data.
public enum Profile {
    /// The same name always gives the same identifier, so the profile's data is found again.
    public static func identifier(for name: String) -> UUID {
        let digest = Array(SHA256.hash(data: Data(name.utf8)).prefix(16))
        return digest.withUnsafeBufferPointer { NSUUID(uuidBytes: $0.baseAddress) as UUID }
    }
}

/// P10-PROFILE (D29): `profile.json` in a profile's folder: what the profile is. A record for a reader (the
/// headmate, the readback); the app derives the store and the service from the name, never from this file,
/// so a damaged file cannot move `Default` off its store.
public struct ProfileInfo: Codable, Equatable {
    public static let fileName = "profile.json"
    public static let current = 1
    public let version: Int
    public let name: String
    public let webStore: String
    public let keychainService: String

    public init(version: Int, name: String, webStore: String, keychainService: String) {
        (self.version, self.name, self.webStore, self.keychainService) = (version, name, webStore, keychainService)
    }

    /// The file's record; nil when there is none or it is not one.
    public static func read(from folder: URL) -> ProfileInfo? {
        guard let bytes = try? Data(contentsOf: folder.appendingPathComponent(fileName)) else { return nil }
        return try? JSONDecoder().decode(ProfileInfo.self, from: bytes)
    }

    /// Written atomically, only when the file does not already hold `self`. Says whether it wrote.
    @discardableResult
    public func write(in folder: URL) throws -> Bool {
        guard Self.read(from: folder) != self else { return false }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        try encoder.encode(self).write(to: folder.appendingPathComponent(Self.fileName), options: .atomic)
        return true
    }
}
