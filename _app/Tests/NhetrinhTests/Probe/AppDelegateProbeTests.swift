import AppKit
import NhetrinhCore
import Testing
@testable import Nhetrinh

/// D23, P0-PROBE-FIX gap 3: a normal launch makes no probe. The app's gate takes the launch
/// environment; without `NHT_READBACK=1` there is no server and no folder for this process.
/// Serialized: the started case makes the folder this process's other cases look for.
@MainActor
@Suite(.serialized)
struct AppDelegateProbeTests {
    private var folder: String { ProbePath.folder(pid: getpid()) }

    private func started(_ env: [String: String]) -> AppDelegate {
        _ = NSApplication.shared
        let delegate = AppDelegate()
        delegate.startProbe(if: env, BrowserWindowController())
        return delegate
    }

    @Test(arguments: [
        [String: String](), ["NHT_READBACK": "0"], ["NHT_READBACK": "true"], ["NHT_READBACK": ""],
        ["NHT_PROFILE": "readback"],
    ])
    func noProbeWithoutTheVariable(env: [String: String]) {
        let delegate = started(env)
        #expect(delegate.probe == nil)
        #expect(!FileManager.default.fileExists(atPath: folder))
    }

    @Test func probeWithTheVariableAndGoneAfterStop() throws {
        let delegate = started(["NHT_READBACK": "1"])
        let probe = try #require(delegate.probe)
        #expect(probe.path == ProbePath.socket(pid: getpid()))
        #expect(FileManager.default.fileExists(atPath: probe.path))
        probe.stop()
        #expect(!FileManager.default.fileExists(atPath: folder))
    }
}
