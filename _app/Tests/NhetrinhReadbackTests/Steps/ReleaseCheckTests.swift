import Foundation
import Testing
@testable import NhetrinhReadback

// P8, R44: the pure parts of the release check, red first (P8-BUILD-1). The step itself runs only after a
// real release, with `--release-url`.

private let zip = URL(string: "https://github.com/owner/nhetrinh/releases/download/v1.0.0/nhetrinh-1.0.0-arm64.zip")
private let digest = String(repeating: "ab", count: 32)

/// The checksum file is the zip's URL + ".sha256", as release.yml uploads it.
@Test func theChecksumSitsNextToTheZip() throws {
    let url = try #require(zip)
    #expect(ReleaseCheck.checksumURL(of: url).absoluteString == url.absoluteString + ".sha256")
}

/// `sha256sum` writes "<64 hex>  <name>"; only a line for the zip's own name with 64 hex digits counts.
@Test(arguments: [
    ("\(digest)  nhetrinh-1.0.0-arm64.zip\n", digest), ("\(digest.uppercased())  nhetrinh-1.0.0-arm64.zip", digest),
    ("\(digest)  other.zip\n", nil), ("abcd  nhetrinh-1.0.0-arm64.zip\n", nil), ("", nil),
] as [(String, String?)])
func theChecksumLineIsRead(text: String, expected: String?) {
    #expect(ReleaseCheck.expectedDigest(text, name: "nhetrinh-1.0.0-arm64.zip") == expected)
}

/// SHA-256 of known bytes ("abc", FIPS 180-2).
@Test func theDigestIsSHA256() {
    #expect(ReleaseCheck.digest(Data("abc".utf8))
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
}

private func result(_ id: String, _ verdict: Verdict) -> StepResult {
    StepResult(id: id, name: id, verdict: verdict, detail: "")
}

/// R44 is PASS only when R1-R8 all pass on the copy; a FAIL wins over a NOT READ BACK; none run is not read.
@Test(arguments: [
    ([Verdict.pass, .pass], Verdict.pass), ([.pass, .notReadBack], .notReadBack), ([.notReadBack, .fail], .fail),
    ([], .notReadBack),
])
func theCopysVerdict(verdicts: [Verdict], expected: Verdict) {
    let results = verdicts.enumerated().map { result("R\($0.offset + 1)", $0.element) }
    #expect(ReleaseCheck.verdict(results) == expected)
}

/// R44 runs only with `--release-url` (never in a plain full run, which keeps _LATEST.md), or when listed.
@Test(arguments: [
    (["readback"], false, true), (["readback", "--release-url", zip?.absoluteString ?? ""], true, false),
    (["readback", "--steps", "R44"], true, false),
] as [([String], Bool, Bool)])
func r44RunsOnlyWhenAsked(arguments: [String], runs: Bool, keeps: Bool) throws {
    let options = try Options(arguments, known: ["R1", "R44"])
    #expect(options.runs("R44") == runs && options.runs("R1") == (arguments.count < 3 || arguments[1] != "--steps"))
    #expect(options.keepsEvidence == keeps)
}

/// Only an https URL of a .zip: anything else is a usage error before any step runs.
@Test(arguments: ["http://example.com/a.zip", "https://example.com/a.tar.gz", "/tmp/a.zip", "https:///a.zip"])
func aReleaseURLIsAnHttpsZip(value: String) {
    #expect(throws: UsageError.self) { try Options(["readback", "--release-url", value], known: ["R44"]) }
}
