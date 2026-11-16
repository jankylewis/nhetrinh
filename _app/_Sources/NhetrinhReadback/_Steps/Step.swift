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

    /// The prefix of every identifier the app sets on its own views.
    static let ownPrefix = "nhetrinh."

    /// What a step throws when no element `id` is in the window. Other own identifiers read: the app
    /// lost this one, FAIL. None read (20:01: children read, no `nhetrinh.*`): the tree was not read,
    /// NOT READ BACK with what was read. 0 children: a refused read, NOT READ BACK with a re-grant.
    static func missing(_ id: String, in read: WindowRead, grantee: String = Grant.grantee()) -> StepError {
        guard !read.hasOwnID else { return .fail("no element `\(id)` in the window") }
        guard read.children > 0 else {
            return .cannotDrive(reason("no element `\(id)`, \(read.summary)", grantee: grantee))
        }
        return .cannotDrive("no element `\(id)`: none of the app's identifiers (\(ownPrefix)*) "
            + "is in the window, its tree was not read (\(read.summary))")
    }
}

/// What the readback read of a window in which an element was not found.
struct WindowRead {
    let title: String
    let children: Int
    /// The roles of the first children, in order; "" when a role read is empty.
    let firstRoles: [String]
    /// The accessibility error of reading the window's children, 0 when it reads.
    let error: Int32
    /// Whether any identifier starting with `EmptyReads.ownPrefix` is anywhere in the window's tree.
    let hasOwnID: Bool

    var summary: String {
        let roles = firstRoles.map { $0.isEmpty ? "(empty)" : $0 }.joined(separator: ", ")
        return "window \"\(title)\", \(children) children, first roles [\(roles)], read error \(error)"
    }
}

/// NT-GAT-008, readback 20:07: the first element `AXWindows` gave had the children [AXApplication,
/// AXMenuBar], not a window. A step acts only on an element whose role is AXWindow.
enum WindowRole {
    static let window = "AXWindow"

    /// The index of the first window among the roles `AXWindows` read; nil when nothing was read
    /// yet. Elements read but none a window: NOT READ BACK, naming the roles, never FAIL of the app.
    static func pick(_ roles: [String]) throws -> Int? {
        guard !roles.isEmpty else { return nil }
        if let index = roles.firstIndex(of: window) { return index }
        let seen = roles.map { $0.isEmpty ? "(empty)" : $0 }.joined(separator: ", ")
        throw StepError.cannotDrive("the app's windows read as [\(seen)], none has the role \(window): "
            + "the Accessibility tree read is not the app's window")
    }
}
