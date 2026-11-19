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
    var adHoc = false
    var interactionAllowed: Bool
    var calls: [Call] = []
    var statuses: [String: OSStatus] = [:]
    var stored = Data("kept".utf8)
    /// Accounts with no item: a copy of one answers errSecItemNotFound, whatever `statuses` says.
    var missing: Set<String> = []

    init(interaction: Bool) { interactionAllowed = interaction }

    private func record(_ kind: String, _ query: [String: Any], data: Data? = nil) -> OSStatus {
        calls.append(Call(kind: kind, service: query[kSecAttrService as String] as? String,
                          account: query[kSecAttrAccount as String] as? String, data: data,
                          interaction: interactionAllowed))
        return statuses[kind] ?? errSecSuccess
    }

    func copy(_ query: [String: Any]) -> (OSStatus, Data?) {
        var status = record("copy", query)
        if missing.contains(query[kSecAttrAccount as String] as? String ?? "") { status = errSecItemNotFound }
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

    private func run(_ operation: String, _ statuses: [String: OSStatus], interaction: Bool = true,
                     adHoc: Bool = false) -> RecordedCalls {
        let fake = RecordedCalls(interaction: interaction)
        (fake.statuses, fake.adHoc) = (statuses, adHoc)
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

    /// ONE item per profile and signing kind: every call names the profile's service and the account of its
    /// kind, never a wider query (no service-wide update: nothing piles up). An ad-hoc build and an identity-signed
    /// one never share an item: one first kept ad hoc is unreadable by a signed build forever (RECHECK round 2).
    @Test(arguments: [(adHoc: false, account: "signins.signed"), (adHoc: true, account: "signins.adhoc")])
    func everyCallIsTheProfilesOneItemOfItsSigningKind(adHoc: Bool, account: String) {
        for (operation, statuses) in Self.runs {
            for call in run(operation, statuses, adHoc: adHoc).calls {
                let old = !adHoc && call.account == KeychainSecrets.oldAccount && call.kind != "add"
                    && call.kind != "update"  // a signed build reads and deletes the old item, never writes it
                #expect(call.service == Self.service && (call.account == account || old),
                        "\(operation) \(statuses): \(call.kind) on \(call.service ?? "-") / \(call.account ?? "-")")
            }
        }
        #expect(KeychainSecrets.account(adHoc: adHoc) == account)
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
    /// A signed build then deletes the old account's item too (the last delete).
    @Test(arguments: [(delete: errSecSuccess, kinds: ["delete", "delete"]),
                      (delete: errSecItemNotFound, kinds: ["delete", "delete"]),
                      (delete: errSecInvalidOwnerEdit, kinds: ["delete", "update", "delete"])])
    func deleteRemovesOrEmptiesTheOneItem(delete: OSStatus, kinds: [String]) {
        let fake = run("delete", ["delete": delete])
        #expect(fake.calls.map(\.kind) == kinds)
        #expect(fake.calls.last?.account == KeychainSecrets.oldAccount)
        if kinds.contains("update") { #expect(fake.calls.first { $0.kind == "update" }?.data == Data()) }
    }

    /// An update keeps the sign-ins: a signed build with no item of its own reads the old account's item once,
    /// then deletes it. An ad-hoc build never touches it; with no item anywhere nothing is deleted.
    @Test(arguments: [
        (adHoc: false, missing: ["signins.signed"], read: true, calls: ["copy signins.signed", "copy signins",
                                                                          "delete signins"]),
        (adHoc: false, missing: ["signins.signed", "signins"], read: false,
         calls: ["copy signins.signed", "copy signins"]),
        (adHoc: true, missing: ["signins.adhoc"], read: false, calls: ["copy signins.adhoc"]),
        (adHoc: false, missing: [], read: true, calls: ["copy signins.signed"]),
    ] as [(Bool, Set<String>, Bool, [String])])
    func anUpdateReadsTheOldItemOnce(adHoc: Bool, missing: Set<String>, read: Bool, calls: [String]) throws {
        let fake = RecordedCalls(interaction: false)
        (fake.adHoc, fake.missing) = (adHoc, missing)
        let data = try KeychainSecrets(calls: fake).read(service: Self.service)
        #expect((data == fake.stored) == read)
        #expect(fake.calls.map { "\($0.kind) \($0.account ?? "-")" } == calls)
    }

    /// An item this signature may not read (an ad-hoc build after a signed one) is an error by its status,
    /// never a prompt: the keeper logs the kind and restores nothing.
    @Test func anItemOfAnotherSignatureIsAnErrorNotAPrompt() {
        let secrets = KeychainSecrets(calls: RecordedCalls(interaction: true))
        (secrets.calls as? RecordedCalls)?.statuses = ["copy": errSecAuthFailed]
        #expect(throws: SecretsError.status(errSecAuthFailed)) { try secrets.read(service: Self.service) }
    }
}
