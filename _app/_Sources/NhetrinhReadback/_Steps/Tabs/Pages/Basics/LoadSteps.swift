import Foundation
import NhetrinhCore

/// R23 and R24: the error page with Retry, and the HTTP sign-in sheet.
enum LoadSteps {
    /// Kept for the run: the server R23 starts on the port that was closed.
    nonisolated(unsafe) private static var lateServer: TestPages?

    static func retry(_ app: AppSession) throws -> String {
        let port: UInt16
        do { port = try TestPages.freePort() } catch { throw StepError.cannotDrive("no free port: \(error)") }
        let url = "http://127.0.0.1:\(port)/page/7"
        try LifecycleSteps.freshStart(app)
        try app.act(.navigate(url), "address bar: a closed port, Return")
        let reason = ErrorPage.title(for: NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost))
        let error = try SheetDriving.title(app, reason, after: "typed \(url)", timeout: 15)
        try expect(error.address == url, "the error page's address bar shows \"\(error.address)\", not \(url)")
        do { lateServer = try TestPages(port: port) } catch {
            throw StepError.cannotDrive("the server could not start on port \(port): \(error)")
        }
        try SheetDriving.click(app, "#retry", "Retry")
        try SheetDriving.title(app, TestPageContent.title(page: 7), after: "server started, Retry", timeout: 15)
        return "a closed port: the error page \"\(reason)\" at \(url); server started, Retry: the page loaded"
    }

    static func signIn(_ app: AppSession) throws -> String {
        _ = try PageSteps.openTest(app, "/auth", title: nil)
        let first = try SheetDriving.sheet(app, text: "Sign in to 127.0.0.1", timeout: 15)
        try type(app, password: "wrong")
        let again = try SheetDriving.sheet(app, text: "not right", after: first.sheetsShown)
        try type(app, password: BasicPages.password)
        try SheetDriving.title(app, BasicPages.signedInTitle, after: "the right password, Sign In")
        let state = try SheetDriving.gone(app, after: "the right password, Sign In")
        return "a Basic page: the sheet \"\(BasicSteps.oneLine(first.sheet))\"; a wrong password: asked again "
            + "(\"\(BasicSteps.oneLine(again.sheet))\"); the right one: \"\(state.title)\""
    }

    private static func type(_ app: AppSession, password: String) throws {
        try app.act(.sheetField(index: 0, text: BasicPages.user), "type the user name")
        try app.act(.sheetField(index: 1, text: password), "type the password")
        try SheetDriving.press(app, "Sign In")
    }
}
