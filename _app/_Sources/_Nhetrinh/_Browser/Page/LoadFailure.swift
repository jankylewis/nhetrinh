import AppKit
import NhetrinhCore
import WebKit

/// P3: a load that fails shows the error page (`ErrorPage`) with Retry; a site that asks for a user
/// and password (HTTP Basic, Digest) gets a sign-in sheet. A bad certificate fails as WebKit decides
/// and shows the error page: there is no "proceed anyway" (DECISIONS.md Q5).
extension BrowserWindowController {
    /// The error page in place of the failed load, at the failing address (Retry loads it again).
    func showErrorPage(for failure: Error, in webView: WKWebView) {
        let error = failure as NSError
        guard ErrorPage.shows(error) else { return }
        let html = ErrorPage.html(for: error)
        if let url = ErrorPage.failingURL(of: error) {
            webView.loadSimulatedRequest(URLRequest(url: url), responseHTML: html)
        } else {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    @objc func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                       completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let method = challenge.protectionSpace.authenticationMethod
        guard method == NSURLAuthenticationMethodHTTPBasic || method == NSURLAuthenticationMethodHTTPDigest else {
            return completionHandler(.performDefaultHandling, nil)  // a certificate: WebKit's own check
        }
        let (alert, user, password) = Self.signInSheet(host: challenge.protectionSpace.host,
                                                       again: challenge.previousFailureCount > 0)
        ask(alert, for: webView) { pressed in
            guard pressed == 0 else { return completionHandler(.rejectProtectionSpace, nil) }
            let credential = URLCredential(user: user.stringValue, password: password.stringValue,
                                           persistence: .forSession)
            completionHandler(.useCredential, credential)
        }
    }

    /// The sign-in sheet: the user name field, then the password field.
    static func signInSheet(host: String, again: Bool) -> (NSAlert, NSTextField, NSSecureTextField) {
        let alert = NSAlert()
        alert.messageText = "Sign in to \(host)"
        alert.informativeText = again ? "The user name or the password was not right. Try again."
            : "This site asks for a user name and a password."
        let user = NSTextField(frame: NSRect(x: 0, y: 32, width: 260, height: 24))
        user.placeholderString = "User name"
        let password = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        password.placeholderString = "Password"
        let fields = NSView(frame: NSRect(x: 0, y: 0, width: 260, height: 56))
        fields.addSubview(user)
        fields.addSubview(password)
        alert.accessoryView = fields
        alert.window.initialFirstResponder = user
        alert.addButton(withTitle: "Sign In")
        alert.addButton(withTitle: "Cancel")
        return (alert, user, password)
    }
}
