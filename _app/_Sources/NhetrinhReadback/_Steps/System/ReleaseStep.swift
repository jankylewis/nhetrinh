import CryptoKit
import Foundation

/// R44 (P8, hubs/product/plan/M3_V1_RELEASE.md): the released zip as anyone gets it. Download it and its
/// `.sha256` from the Release, check the SHA-256, unzip to a new temporary folder, and run R1-R8 on that
/// copy. Runs only with `--release-url <zip>`, after a real release. The copy is downloaded by this tool,
/// so it carries no quarantine: the macOS first-open warning is not read back (README, by hand).
enum ReleaseCheck {
    static let step = Step(id: "R44", name: "the released zip: SHA-256 checked, R1-R8 PASS on that copy", run: run)

    static func checksumURL(of zip: URL) -> URL { URL(string: zip.absoluteString + ".sha256") ?? zip }

    /// The digest `sha256sum` wrote for `name` ("<64 hex>  <name>"), lower case; nil when there is none.
    static func expectedDigest(_ text: String, name: String) -> String? {
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count == 2, parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "*")) == name else {
                continue
            }
            let hex = parts[0].lowercased()
            if hex.count == 64, hex.allSatisfy(\.isHexDigit) { return hex }
        }
        return nil
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    /// PASS only when every step passed; a FAIL wins over a NOT READ BACK; no step: not read back.
    static func verdict(_ results: [StepResult]) -> Verdict {
        if results.contains(where: { $0.verdict == .fail }) { return .fail }
        if results.isEmpty || results.contains(where: { $0.verdict == .notReadBack }) { return .notReadBack }
        return .pass
    }

    static func run(_ app: AppSession) throws -> String {
        guard let zip = app.releaseURL else {
            throw StepError.cannotDrive("no --release-url: R44 runs after a release")
        }
        let bytes = try fetch(zip)
        let sums = String(decoding: try fetch(checksumURL(of: zip)), as: UTF8.self)
        guard let expected = expectedDigest(sums, name: zip.lastPathComponent) else {
            let sumsName = checksumURL(of: zip).lastPathComponent
            throw StepError.fail("\(sumsName) has no SHA-256 line for \(zip.lastPathComponent)")
        }
        let actual = digest(bytes)
        try expect(actual == expected, "SHA-256 \(actual), the Release says \(expected)")
        app.quit()  // one app instance on the machine
        let copy = try unzip(bytes, name: zip.lastPathComponent)
        defer { try? FileManager.default.removeItem(at: copy.deletingLastPathComponent()) }
        let session = AppSession(appURL: copy)
        session.allowFocus = false
        let results = Runner.run(BaseSteps.all, in: session)
        session.quit()
        let lines = results.map { "\($0.id) \($0.verdict.rawValue)" }.joined(separator: ", ")
        let seen = "\(zip.lastPathComponent) \(bytes.count / 1024) KB, SHA-256 \(actual.prefix(12))… matches; "
            + "on the copy: \(lines)"
        switch verdict(results) {
        case .pass: return seen + "; the first-open warning: not read back (no quarantine on this copy)"
        case .fail: throw StepError.fail(seen)
        case .notReadBack: throw StepError.cannotDrive(seen)
        }
    }

    private static func fetch(_ url: URL) throws -> Data {
        var result: Result<Data, Error> = .failure(StepError.cannotDrive("\(url.lastPathComponent): no answer"))
        let done = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: url) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if let data, status == 200 { result = .success(data) } else {
                let why = "\(url.lastPathComponent): HTTP \(status) \(error?.localizedDescription ?? "")"
                result = .failure(StepError.cannotDrive(why))
            }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 120)
        return try result.get()
    }

    /// The zip unzipped with `ditto` into a new temporary folder; the app inside it.
    private static func unzip(_ bytes: Data, name: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-release-\(UUID())")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent(name)
        try bytes.write(to: file)
        let ditto = Process()
        ditto.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        ditto.arguments = ["-x", "-k", file.path, folder.path]
        try ditto.run()
        ditto.waitUntilExit()
        let app = folder.appendingPathComponent("nhetrinh.app")
        guard ditto.terminationStatus == 0, FileManager.default.fileExists(atPath: app.path) else {
            throw StepError.fail("\(name) did not unzip to nhetrinh.app (ditto \(ditto.terminationStatus))")
        }
        return app
    }
}
