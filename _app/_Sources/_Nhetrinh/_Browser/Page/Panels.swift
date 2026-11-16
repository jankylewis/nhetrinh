import AppKit
import NhetrinhCore
import WebKit

/// P3: file upload (the open panel), File > Print…, camera and microphone per site.
extension BrowserWindowController {
    /// `<input type="file">`: the macOS open panel, as a sheet on the window.
    @objc func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                       initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        guard let window else { return completionHandler(nil) }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        sheets.openPanel = panel
        sheets.shown += 1
        panel.beginSheetModal(for: window) { [weak self] response in
            if self?.sheets.openPanel === panel { self?.sheets.openPanel = nil }
            completionHandler(response == .OK ? panel.urls : nil)
        }
    }

    /// File > Print… (⌘P): the selected page, through the print panel as a sheet.
    @objc func printPage(_ sender: Any?) {
        guard let webView = current, let window, window.attachedSheet == nil else { return }
        let operation = webView.printOperation(with: NSPrintInfo.shared)
        operation.view?.frame = webView.bounds  // WebKit prints nothing from a view with no frame
        sheets.printing = true
        sheets.shown += 1
        operation.runModal(for: window, delegate: self, didRun: #selector(printDidRun(_:success:contextInfo:)),
                           contextInfo: nil)
    }

    @objc func printDidRun(_ operation: NSPrintOperation, success: Bool, contextInfo: UnsafeMutableRawPointer?) {
        sheets.printing = false
    }

    /// Camera and microphone: asked once per site and kind until the app quits. macOS then asks for
    /// the app itself, once (Info.plist carries the two usage texts).
    @objc func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                       initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                       decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let kind: MediaKind = type == .camera ? .camera : type == .microphone ? .microphone : .cameraAndMicrophone
        let host = origin.host
        if let kept = sheets.permissions.decision(host: host, kind: kind) {
            return decisionHandler(kept ? .grant : .deny)
        }
        let alert = NSAlert()
        alert.messageText = SitePermissions.question(host: host, kind: kind)
        alert.informativeText = "nhetrinh keeps your answer for this site until it quits."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don't Allow")
        ask(alert, for: webView) { [weak self] pressed in
            self?.sheets.permissions.record(pressed == 0, host: host, kind: kind)
            decisionHandler(pressed == 0 ? .grant : .deny)
        }
    }
}
