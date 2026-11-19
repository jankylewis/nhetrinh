import Foundation
import Security

/// P9-REMEMBER (D28): the Security calls `KeychainSecrets` makes, behind a seam so a test can record each one
/// (its query, and whether user interaction was off while it ran) without a Keychain (RECHECK D1).
protocol KeychainCalls: AnyObject {
    /// Whether these calls may reach a Keychain at all. The real ones: only inside the launched app.
    var reachesKeychain: Bool { get }
    /// Whether this build is signed ad hoc (GitHub CI, no local identity) rather than with an identity.
    var adHoc: Bool { get }
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
    /// From this process's own signature, read once; unknown counts as ad hoc (its own account, never shared).
    let adHoc: Bool = {
        var code: SecCode?
        var staticCode: SecStaticCode?
        var info: CFDictionary?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, [], &info) == errSecSuccess,
              let flags = (info as? [String: Any])?[kSecCodeInfoFlags as String] as? UInt32 else { return true }
        return flags & SecCodeSignatureFlags.adhoc.rawValue != 0
    }()

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
