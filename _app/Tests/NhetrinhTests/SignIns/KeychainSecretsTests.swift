import Foundation
import NhetrinhCore
import Security
import Testing
@testable import Nhetrinh

/// P9-REMEMBER round 2 (RECHECK_P9_REMEMBER.md D1): what `KeychainSecrets` asks the Keychain, on a fake that
/// records every Security call: its kind, its query, and whether user interaction was off while it ran.
/// No Keychain is reached: the fake answers with the statuses a test gives it.
final class RecordedCalls: KeychainCalls {
    struct Call: Equatable {
        let kind: String
        let service: String?
        let account: String?
        let data: Data?
        let interaction: Bool
    }

    let reachesKeychain = true
    var interactionAllowed: Bool
    var calls: [Call] = []
    var statuses: [String: OSStatus] = [:]
    var stored = Data("kept".utf8)

    init(interaction: Bool) { interactionAllowed = interaction }

    private func record(_ kind: String, _ query: [String: Any], data: Data? = nil) -> OSStatus {
        calls.append(Call(kind: kind, service: query[kSecAttrService as String] as? String,
                          account: query[kSecAttrAccount as String] as? String, data: data,
                          interaction: interactionAllowed))
        return statuses[kind] ?? errSecSuccess
    }

    func copy(_ query: [String: Any]) -> (OSStatus, Data?) {
        let status = record("copy", query)
        return (status, status == errSecSuccess ? stored : nil)
    }

    func add(_ item: [String: Any]) -> OSStatus { record("add", item, data: item[kSecValueData as String] as? Data) }

    func update(_ query: [String: Any], to changes: [String: Any]) -> OSStatus {
        record("update", query, data: changes[kSecValueData as String] as? Data)
    }

    func delete(_ query: [String: Any]) -> OSStatus { record("delete", query) }
}

@MainActor
struct KeychainSecretsTests {
    static let service = SignIns.service(profile: "readback")
    static let data = Data("fake-1".utf8)

    /// Every operation, with the statuses that send it down each of its paths.
    static let runs: [(String, [String: OSStatus])] = [
        ("read", [:]), ("read", ["copy": errSecItemNotFound]), ("read", ["copy": errSecAuthFailed]),
        ("write", [:]), ("write", ["update": errSecItemNotFound]), ("write", ["update": errSecAuthFailed]),
        ("delete", [:]), ("delete", ["delete": errSecItemNotFound]), ("delete", ["delete": errSecInvalidOwnerEdit]),
    ]

    private func run(_ operation: String, _ statuses: [String: OSStatus], interaction: Bool = true) -> RecordedCalls {
        let fake = RecordedCalls(interaction: interaction)
        fake.statuses = statuses
        let secrets = KeychainSecrets(calls: fake)
        switch operation {
        case "read": _ = try? secrets.read(service: Self.service)
        case "write": try? secrets.write(Self.data, service: Self.service)
        default: try? secrets.delete(service: Self.service)
        }
        return fake
    }

    /// Every Security call runs with user interaction off; afterwards the setting is as it was, also on errors.
    @Test(arguments: [true, false])
    func everyCallRunsWithInteractionOffThenPutsItBack(before: Bool) {
        for (operation, statuses) in Self.runs {
            let fake = run(operation, statuses, interaction: before)
            #expect(!fake.calls.isEmpty, "\(operation) \(statuses) made no call")
            #expect(fake.calls.allSatisfy { !$0.interaction }, "\(operation) \(statuses): a call could ask")
            #expect(fake.interactionAllowed == before, "\(operation) \(statuses): interaction not put back")
        }
    }

    /// ONE item per profile: every call names the profile's service and the one account, never a wider query
    /// (no service-wide update: nothing piles up), whatever build or signature runs.
    @Test func everyCallIsTheProfilesOneItem() {
        for (operation, statuses) in Self.runs {
            for call in run(operation, statuses).calls {
                #expect(call.service == Self.service && call.account == KeychainSecrets.account,
                        "\(operation) \(statuses): \(call.kind) on \(call.service ?? "-") / \(call.account ?? "-")")
            }
        }
        #expect(KeychainSecrets.account == "signins")
    }

    /// Write updates the item in place (allowed whatever signature made it); only a missing item is added.
    @Test(arguments: [(update: errSecSuccess, kinds: ["update"]),
                      (update: errSecItemNotFound, kinds: ["update", "add"])])
    func writeUpdatesInPlaceAndAddsOnlyAMissingItem(update: OSStatus, kinds: [String]) {
        let fake = run("write", ["update": update])
        #expect(fake.calls.map(\.kind) == kinds)
        #expect(fake.calls.allSatisfy { $0.data == Self.data })
    }

    /// Delete removes the item; one this signature may not delete (another signer's) is emptied in place.
    @Test(arguments: [(delete: errSecSuccess, kinds: ["delete"]), (delete: errSecItemNotFound, kinds: ["delete"]),
                      (delete: errSecInvalidOwnerEdit, kinds: ["delete", "update"])])
    func deleteRemovesOrEmptiesTheOneItem(delete: OSStatus, kinds: [String]) {
        let fake = run("delete", ["delete": delete])
        #expect(fake.calls.map(\.kind) == kinds)
        if kinds.contains("update") { #expect(fake.calls.last?.data == Data()) }
    }

    /// An item this signature may not read (an ad-hoc build after a signed one) is an error by its status,
    /// never a prompt: the keeper logs the kind and restores nothing.
    @Test func anItemOfAnotherSignatureIsAnErrorNotAPrompt() {
        let secrets = KeychainSecrets(calls: RecordedCalls(interaction: true))
        (secrets.calls as? RecordedCalls)?.statuses = ["copy": errSecAuthFailed]
        #expect(throws: SecretsError.status(errSecAuthFailed)) { try secrets.read(service: Self.service) }
    }
}
