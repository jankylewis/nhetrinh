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
