import Foundation
import NhetrinhCore

/// R23 and R24: the error page with Retry, and the HTTP sign-in sheet. R52: a plain http page on a name.
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

    /// R52 (P8-ATS-1, NT-BUG-019): App Transport Security lets plain http through to localhost and IP addresses
    /// with no key (and, per Apple's ATS documentation as recalled, not proven here, to unqualified names and
    /// `.local` names), so the page is asked for by a qualified name: a `.localhost` name resolves to this machine.
    static let plainHTTPStep = Step(id: "R52", name: "a plain http page on a name (not localhost, not an IP) "
                                    + "loads", run: plainHTTP)
    static let siteName = "site.localhost"

    static func namedURL(port: UInt16, path: String) -> String { "http://\(siteName):\(port)\(path)" }

    /// Whether ATS exempts `host`: localhost, an IPv4 or IPv6 address; also an unqualified name or a `.local`
    /// name (Apple's ATS documentation as recalled, not proven). A step there proves nothing.
    static func exemptFromATS(_ host: String) -> Bool {
        let bare = host.hasPrefix("[") && host.hasSuffix("]") ? String(host.dropFirst().dropLast()) : host
        var v4 = in_addr(), v6 = in6_addr()
        if inet_pton(AF_INET, bare, &v4) == 1 || inet_pton(AF_INET6, bare, &v6) == 1 { return true }
        let name = bare.lowercased().hasSuffix(".") ? String(bare.lowercased().dropLast()) : bare.lowercased()
        return name == "localhost" || !name.contains(".") || name.hasSuffix(".local")
    }

    /// R52 acts only on a name ATS does not exempt; otherwise it is NOT READ BACK (a pass would prove nothing).
    static func requireNotExempt(_ name: String) throws {
        guard exemptFromATS(name) else { return }
        throw StepError.cannotDrive("\(name) is exempt from App Transport Security: R52 would prove nothing there")
    }

    static func plainHTTP(_ app: AppSession) throws -> String {
        try requireNotExempt(siteName)
        let url = namedURL(port: try LifecycleSteps.pages().port, path: "/page/5")
        try LifecycleSteps.freshStart(app)
        try app.act(.navigate(url), "address bar: \(url), Return")
        let state = try SheetDriving.title(app, TestPageContent.title(page: 5), after: "typed \(url)", timeout: 15)
        try expect(state.address == url, "the address bar shows \"\(state.address)\", not \(url)")
        return "plain http by the name \(siteName) (qualified, not .local, not an address: not exempt from ATS): "
            + "\"\(state.title)\" loaded at \(url)"
    }

    private static func type(_ app: AppSession, password: String) throws {
        try app.act(.sheetField(index: 0, text: BasicPages.user), "type the user name")
        try app.act(.sheetField(index: 1, text: password), "type the password")
        try SheetDriving.press(app, "Sign In")
    }
}
