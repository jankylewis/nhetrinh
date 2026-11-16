import Testing
@testable import NhetrinhReadback

// R22 (ruling on NT-TG-006): the readback proves the open panel is shown and Cancel answers nothing
// chosen; the file choice is a unit test, and the line says "file choice: unit test only".

@Test func theLineNamesTheFileChoiceAsUnitTestOnly() {
    #expect(PanelSteps.fileChoiceUnitOnly == "file choice: unit test only")
}

/// The upload page's own script writes the title R22 waits for after Cancel.
@Test func theUploadPageSaysCancel() {
    let body = String(decoding: TestPageContent.reply(path: "/upload").body, as: UTF8.self)
    #expect(body.contains("addEventListener('cancel', () => { document.title = 'file: cancel' })"))
    #expect(BasicPages.uploadCancelTitle == "file: cancel")
}

/// After Cancel: the `cancel` event, or the title unchanged, is nothing chosen.
@Test(arguments: [
    ("file: cancel", "Cancel: the page heard cancel, nothing chosen"),
    ("upload test", "Cancel: nothing chosen (the page's title stays \"upload test\")"),
    ("file: none", "Cancel: nothing chosen (the page's title stays \"file: none\")"),
])
func cancelGivesNothingChosen(title: String, line: String) throws {
    #expect(try PanelSteps.cancelPart(title: title) == line)
}

/// After Cancel the input got a file, or the page is another one: a FAIL, never a PASS.
@Test(arguments: ["file: fixture.txt", "file: ", "nhetrinh test 1"])
func aFileAfterCancelFails(title: String) {
    #expect(throws: StepError.self) { try PanelSteps.cancelPart(title: title) }
}
