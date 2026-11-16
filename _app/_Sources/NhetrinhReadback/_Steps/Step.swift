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
