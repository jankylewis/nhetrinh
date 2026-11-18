import Foundation
import Testing
@testable import NhetrinhReadback

// R52 (P8-ATS-1, NT-BUG-019): a plain http page on a name App Transport Security does not exempt.
// ATS lets localhost and IP addresses through with no key, so a step on 127.0.0.1 passes without the fix.
// Unqualified names and `.local` names are exempt too, per Apple's ATS documentation as recalled: not proven
// here, so the step counts them as exempt and never uses one.

@Test(arguments: [
    ("localhost", true), ("LOCALHOST", true), ("127.0.0.1", true), ("10.0.0.7", true), ("::1", true),
    ("[::1]", true), ("site.localhost", false), ("example.test", false), ("127.0.0.1.example.test", false),
    ("intranet", true), ("printer.local", true), ("PRINTER.LOCAL.", true), ("local.example.test", false),
])
func onlyLocalhostAndAddressesAreExempt(host: String, exempt: Bool) {
    #expect(LoadSteps.exemptFromATS(host) == exempt)
}

/// The step's address is plain http, on the readback's port, by a name ATS does not exempt.
@Test(arguments: [UInt16(8080), 49_152, 65_535])
func theStepsAddressIsPlainHTTPOnANamedHost(port: UInt16) throws {
    let url = try #require(URL(string: LoadSteps.namedURL(port: port, path: "/page/5")))
    #expect(url.scheme == "http")
    #expect(url.port == Int(port))
    #expect(url.path == "/page/5")
    let host = url.host ?? ""
    #expect(host == LoadSteps.siteName)
    #expect(!LoadSteps.exemptFromATS(host))
}

@Test func plainHTTPIsR52() {
    #expect(LoadSteps.plainHTTPStep.id == "R52")
}

/// The step refuses a name ATS exempts before it acts: a pass there would prove nothing (NOT READ BACK).
@Test(arguments: [("localhost", true), ("127.0.0.1", true), ("intranet", true), ("printer.local", true),
                  (LoadSteps.siteName, false)])
func theStepRefusesAnExemptName(name: String, refused: Bool) {
    var refusal = ""
    do {
        try LoadSteps.requireNotExempt(name)
    } catch StepError.cannotDrive(let why) {
        refusal = why
    } catch {
        refusal = "other: \(error)"
    }
    #expect(refusal.isEmpty == !refused)
    if refused { #expect(refusal.contains(name)) }
}
