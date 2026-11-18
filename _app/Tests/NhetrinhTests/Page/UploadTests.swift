import AppKit
import Testing
@testable import Nhetrinh

/// R22's file choice (ruling on NT-TG-006): the readback shows the open panel for the page's input and
/// presses Cancel; the choice of a file is this unit test. A chosen URL is fed to the upload completion
/// as the panel gives it, and the page's input must get exactly that.
@MainActor
struct UploadTests {
    private let fixture = URL(fileURLWithPath: "/tmp/nhetrinh-upload-fixture.txt")
    private let second = URL(fileURLWithPath: "/tmp/nhetrinh-upload-second.png")

    /// The completion WebKit gives the delegate, fed as the panel's sheet ends.
    private func pageGets(_ response: NSApplication.ModalResponse, _ chosen: [URL]) -> [URL]?? {
        var received: [URL]??
        let completionHandler: ([URL]?) -> Void = { received = .some($0) }
        completionHandler(BrowserWindowController.uploadAnswer(response, chosen: chosen))
        return received
    }

    @Test func aChosenFileReachesThePage() {
        #expect(pageGets(.OK, [fixture]) == .some([fixture]))
    }

    @Test func severalChosenFilesReachThePageInOrder() {
        #expect(pageGets(.OK, [fixture, second]) == .some([fixture, second]))
    }

    /// Cancel, a tab closed or left with the panel up (`.abort`, S1), Open with nothing: nothing chosen.
    @Test(arguments: [NSApplication.ModalResponse.cancel, .abort, .stop])
    func nothingChosenReachesThePageAsNil(response: NSApplication.ModalResponse) {
        #expect(pageGets(response, [fixture]) == .some(nil))
    }

    @Test func openWithNoFileIsNothingChosen() {
        #expect(pageGets(.OK, []) == .some(nil))
    }

    /// The panel follows the page's input: `multiple`, `webkitdirectory`.
    @Test(arguments: [(false, false), (true, false), (true, true)])
    func thePanelFollowsTheInput(multiple: Bool, directories: Bool) {
        let panel = BrowserWindowController.openPanel(multiple: multiple, directories: directories)
        #expect(panel.allowsMultipleSelection == multiple && panel.canChooseDirectories == directories)
        #expect(panel.canChooseFiles)
    }
}
