import Foundation

/// R55 (NT-BUG-027): a page from a file on the Mac, in a subfolder, uses its parent's style and links there, as
/// the storybook pages do (`../style.css`, `../other.html`). The page sets its own title from the style it got:
/// "margin 37px" only when `../s.css` was read. The files are the readback's own, in a temporary folder.
enum LocalPageStep {
    static let step = Step(id: "R55", name: "a local page in a subfolder uses `../` style and opens a `../` link",
                           run: run)

    static func run(_ app: AppSession) throws -> String {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-r55-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let page = try write(in: folder)
        try LifecycleSteps.freshStart(app)
        try app.act(.navigate(page.absoluteString), "address bar: \(page.lastPathComponent) in sub/, Return")
        try SheetDriving.title(app, "margin 37px", after: "opened \(page.lastPathComponent)", timeout: 15)
        try app.act(.click("a"), "page: click the ../other.html link")
        try SheetDriving.title(app, "parent page", after: "clicked ../other.html", timeout: 15)
        return "sub/page.html read ../s.css (title \"margin 37px\"); its ../other.html link opened (\"parent page\")"
    }

    private static func write(in folder: URL) throws -> URL {
        let sub = folder.appendingPathComponent("sub")
        do {
            try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
            try Data("body { margin-left: 37px }".utf8).write(to: folder.appendingPathComponent("s.css"))
            try Data("<title>parent page</title>".utf8).write(to: folder.appendingPathComponent("other.html"))
            let html = "<title>child</title><link rel=stylesheet href=../s.css><a href=../other.html>up</a>"
                + "<script>onload = () => document.title = 'margin ' + getComputedStyle(document.body).marginLeft"
                + "</script>"
            let page = sub.appendingPathComponent("page.html")
            try Data(html.utf8).write(to: page)
            return page
        } catch {
            throw StepError.cannotDrive("the test files could not be written: \(error)")
        }
    }
}
