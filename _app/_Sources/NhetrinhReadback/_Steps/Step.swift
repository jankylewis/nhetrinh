import Foundation

enum Verdict: String {
    case pass = "PASS"
    case fail = "FAIL"
    case notReadBack = "NOT READ BACK"
}

struct StepResult {
    let id: String
    let name: String
    let verdict: Verdict
    let detail: String
}

/// What a step throws: `fail` when it ran and the app is wrong, `cannotDrive` when it could not
/// run at all. A step that cannot run is reported as NOT READ BACK; it is never counted as passed.
enum StepError: Error {
    case fail(String)
    case cannotDrive(String)
}

/// One readback step. `run` acts on the app as its user would and returns what it saw.
struct Step {
    let id: String
    let name: String
    let run: (AppSession) throws -> String
}

enum Runner {
    static func run(_ steps: [Step], in session: AppSession) -> [StepResult] {
        steps.map { step in
            let (verdict, detail) = outcome(of: step, in: session)
            FileHandle.standardError.write(Data("\(step.id) \(verdict.rawValue): \(detail)\n".utf8))
            return StepResult(id: step.id, name: step.name, verdict: verdict, detail: detail)
        }
    }

    private static func outcome(of step: Step, in session: AppSession) -> (Verdict, String) {
        do {
            return (.pass, try step.run(session))
        } catch StepError.fail(let why) {
            return (.fail, why)
        } catch StepError.cannotDrive(let why) {
            return (.notReadBack, why)
        } catch {
            return (.fail, "unexpected error: \(error.localizedDescription)")
        }
    }
}

/// Poll `condition` until it is true or `timeout` seconds have passed. Returns the last answer.
@discardableResult
func waitUntil(_ timeout: TimeInterval, every interval: TimeInterval = 0.1, _ condition: () -> Bool) -> Bool {
    let end = Date().addingTimeInterval(timeout)
    while Date() < end {
        if condition() { return true }
        Thread.sleep(forTimeInterval: interval)
    }
    return condition()
}

/// Throw `StepError.fail` with what was seen, unless `condition` holds.
func expect(_ condition: Bool, _ seen: @autoclosure () -> String) throws {
    if !condition { throw StepError.fail(seen()) }
}

/// NT-TG-003, readback 19:51: the grant record was kept and `AXIsProcessTrusted` was true, yet every
/// read came back empty. A window always has children (its close, minimise and zoom buttons at
/// least) and the Dock always has items, so a window with none, or 0 Dock items, is a read that was
/// refused: the step is NOT READ BACK and asks for a new grant, never a FAIL of the app.
enum EmptyReads {
    static func reason(_ seen: String, error: Int32? = nil, grantee: String = Grant.grantee()) -> String {
        "Accessibility reads are empty: re-grant \(grantee) (\(seen)" + (error.map { ", read error \($0))" } ?? ")")
    }

    /// What a step throws when no element `id` is in a window with `children` children.
    static func missing(_ id: String, children: Int, error: Int32, grantee: String = Grant.grantee()) -> StepError {
        guard children == 0 else { return .fail("no element `\(id)` in the window") }
        return .cannotDrive(reason("no element `\(id)`, the window has 0 children", error: error, grantee: grantee))
    }
}
