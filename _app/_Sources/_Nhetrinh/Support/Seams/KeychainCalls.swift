import Foundation
import Security

/// P9-REMEMBER (D28): the Security calls `KeychainSecrets` makes, behind a seam so a test can record each one
/// (its query, and whether user interaction was off while it ran) without a Keychain (RECHECK D1).
protocol KeychainCalls: AnyObject {
    /// Whether these calls may reach a Keychain at all. The real ones: only inside the launched app.
    var reachesKeychain: Bool { get }
    var interactionAllowed: Bool { get set }
    func copy(_ query: [String: Any]) -> (OSStatus, Data?)
    func add(_ item: [String: Any]) -> OSStatus
    func update(_ query: [String: Any], to changes: [String: Any]) -> OSStatus
    func delete(_ query: [String: Any]) -> OSStatus
}

/// The login Keychain itself. Outside the launched app `reachesKeychain` is false and no caller gets past
/// `KeychainSecrets.query`: nothing here runs in a unit test, whatever the test passes.
final class SecurityCalls: KeychainCalls {
    let reachesKeychain = KeychainSecrets.allowed(Bundle.main.bundleIdentifier)

    // Deprecated since macOS 10.10, yet the only switch for the file-based login Keychain's access prompt:
    // LAContext's interactionNotAllowed does not cover it (NT-BLD-006).
    var interactionAllowed: Bool {
        get {
            var allowed: DarwinBoolean = true
            SecKeychainGetUserInteractionAllowed(&allowed)
            return allowed.boolValue
        }
        set { SecKeychainSetUserInteractionAllowed(newValue) }
    }

    func copy(_ query: [String: Any]) -> (OSStatus, Data?) {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result as? Data)
    }

    func add(_ item: [String: Any]) -> OSStatus { SecItemAdd(item as CFDictionary, nil) }

    func update(_ query: [String: Any], to changes: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, changes as CFDictionary)
    }

    func delete(_ query: [String: Any]) -> OSStatus { SecItemDelete(query as CFDictionary) }
}
