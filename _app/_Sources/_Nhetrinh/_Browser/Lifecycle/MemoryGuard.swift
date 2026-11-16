import AppKit
import NhetrinhCore

/// P6 memory guard (hubs/product/plan/M3_V1_RELEASE.md): macOS says memory is short, nhetrinh gives
/// memory back at once. The readback cannot make real pressure (never on the headmate's machine): it
/// sends the probe's `pressure` request (NHT_READBACK=1 only), which takes the same `relieve` path.
final class MemoryGuard {
    private let source: DispatchSourceMemoryPressure

    init(_ relieve: @escaping (UnloadPolicy.Pressure) -> Void) {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.normal, .warning, .critical],
                                                             queue: .main)
        source.setEventHandler { [weak source] in
            guard let event = source?.data else { return }
            relieve(Self.level(event))
        }
        source.activate()
        self.source = source
    }

    deinit { source.cancel() }

    /// The most severe level in macOS's event.
    static func level(_ event: DispatchSource.MemoryPressureEvent) -> UnloadPolicy.Pressure {
        if event.contains(.critical) { return .critical }
        return event.contains(.warning) ? .warning : .normal
    }
}

extension BrowserWindowController {
    /// Listen to macOS from now on; a normal launch and a readback launch alike.
    func startMemoryGuard() {
        memoryGuard = MemoryGuard { [weak self] level in self?.relieve(level) }
    }

    /// The readback's "simulate pressure" (P6): only the probe calls it, and the probe exists only with
    /// NHT_READBACK=1. It takes the path a macOS event takes; real system pressure is never made.
    func simulatePressure(_ level: UnloadPolicy.Pressure) -> ProbeResponse {
        Log.web.info("memory pressure simulated by the readback probe")
        relieve(level)
        return .done
    }

    /// Give memory back at `level`: the background tabs the policy names give their page process back
    /// (a playing tab is kept, NT-TAB-001); at critical the favicon cache is emptied too (the rows keep
    /// the icons they show). Normal changes nothing the idle timer does not do.
    func relieve(_ level: UnloadPolicy.Pressure) {
        Log.web.info("memory pressure: \(level.rawValue, privacy: .public)")
        unloadIdleTabs(pressure: level)
        if level == .critical { favicons.empty() }
    }
}
