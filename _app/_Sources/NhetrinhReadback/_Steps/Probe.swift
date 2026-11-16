import Foundation
import NhetrinhCore

/// D23: R1, R3-R7 read and act through the app's readback probe, not through Accessibility (NT-TG-003).
/// The app opens it only when started with `NHT_READBACK=1`. What it answers decides the verdict.
enum ProbeReply {
    /// The index of the row `fromEnd` places above the last (0 is the last) among `count` rows;
    /// nil when there are not enough rows.
    static func rowIndex(fromEnd: Int, count: Int) -> Int? {
        guard fromEnd >= 0, fromEnd < count else { return nil }
        return count - 1 - fromEnd
    }

    /// The app's state; any other answer means the app could not be read: NOT READ BACK.
    static func state(_ response: ProbeResponse) throws -> ProbeState {
        switch response {
        case .state(let state): return state
        case .done: throw StepError.cannotDrive("the probe answered `done` to a state request")
        case .failed(let why): throw StepError.cannotDrive("the probe could not read the app: \(why)")
        }
    }

    /// An action the app refused, as its user would have seen it refused, is FAIL.
    static func acted(_ response: ProbeResponse, doing action: String) throws {
        switch response {
        case .done: return
        case .failed(let why): throw StepError.fail("\(action): \(why)")
        case .state: throw StepError.cannotDrive("\(action): the probe answered a state, not an action")
        }
    }

    /// The probe could not be reached: the app was not read, never a FAIL of it. Never a path.
    static func unreachable(_ error: Error) -> StepError {
        let cause = (error as? ProbeError)?.description ?? error.localizedDescription
        return .cannotDrive("the app answers no readback probe (NHT_READBACK=1): \(cause); "
            + "an app built before D23 has none: build and install the current one")
    }
}

extension AppSession {
    /// Send one request to the running app's probe, starting the app with the probe first if needed.
    func probe(_ request: ProbeRequest) throws -> ProbeResponse {
        if !isRunning || !probing { try launch(probe: true) }
        let path = ProbePath.socket(pid: pid)
        waitUntil(10) { FileManager.default.fileExists(atPath: path) }
        do {
            return try ProbeClient.send(request, to: path)
        } catch {
            throw ProbeReply.unreachable(error)
        }
    }

    func state() throws -> ProbeState { try ProbeReply.state(probe(.state)) }
    func rowCount() throws -> Int { try state().rows.count }
    func addressText() throws -> String { try state().address }

    /// Act as the user does; `action` names it in the verdict ("File > New Tab").
    func act(_ request: ProbeRequest, _ action: String) throws {
        try ProbeReply.acted(probe(request), doing: action)
    }

    /// Select the sidebar row `fromEnd` places above the last, as a click does, on a fresh read of the rows.
    func selectRow(fromEnd offset: Int) throws {
        let count = try rowCount()
        guard let index = ProbeReply.rowIndex(fromEnd: offset, count: count) else {
            throw StepError.fail("the sidebar has \(count) row(s); \(offset + 1) are needed")
        }
        try act(.select(index), "select sidebar row \(index + 1)")
    }
}
