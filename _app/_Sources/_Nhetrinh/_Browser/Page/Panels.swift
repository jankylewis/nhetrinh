import AppKit
import NhetrinhCore
import WebKit

/// P3: file upload (the open panel), File > Print…, camera and microphone per site.
extension BrowserWindowController {
    /// `<input type="file">`: the macOS open panel, as a sheet on the window.
    @objc func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                       initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        guard let window else { return completionHandler(nil) }
        let panel = Self.openPanel(multiple: parameters.allowsMultipleSelection,
                                   directories: parameters.allowsDirectories)
        sheets.openPanel = panel
        sheets.shown += 1
        keep(panel, for: webView)
        panel.beginSheetModal(for: window) { [weak self] response in
            self?.forget(panel)
            if self?.sheets.openPanel === panel { self?.sheets.openPanel = nil }
            completionHandler(Self.uploadAnswer(response, chosen: panel.urls))
        }
    }

    /// The open panel for a page's file input: one file or several, folders when the input takes them.
    static func openPanel(multiple: Bool, directories: Bool) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = multiple
        panel.canChooseDirectories = directories
        panel.canChooseFiles = true
        return panel
    }

    /// What the page's input gets: the chosen files after Open; nil (nothing chosen) after Cancel, after
    /// its tab was closed or left (S1), or when Open came with no file. R22 reads back the panel and
    /// Cancel; the file choice is this function's unit test (ruling on NT-TG-006).
    static func uploadAnswer(_ response: NSApplication.ModalResponse, chosen: [URL]) -> [URL]? {
        response == .OK && !chosen.isEmpty ? chosen : nil
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

    /// Camera and microphone: asked once per site (scheme, host, port) and kind until the app quits.
    /// macOS then asks for the app itself, once (Info.plist carries the two usage texts).
    @objc func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                       initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                       decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        let kind: MediaKind = type == .camera ? .camera : type == .microphone ? .microphone : .cameraAndMicrophone
        let host = origin.host
        let site = SitePermissions.site(scheme: origin.protocol, host: host, port: origin.port)
        if let kept = sheets.permissions.decision(site: site, kind: kind) {
            return decisionHandler(kept ? .grant : .deny)
        }
        let alert = NSAlert()
        alert.messageText = SitePermissions.question(host: host, kind: kind)
        alert.informativeText = "nhetrinh keeps your answer for this site until it quits."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Don't Allow")
        ask(alert, for: webView) { [weak self] pressed in
            if pressed >= 0 { self?.sheets.permissions.record(pressed == 0, site: site, kind: kind) }  // S1
            decisionHandler(pressed == 0 ? .grant : .deny)
        }
    }
}
