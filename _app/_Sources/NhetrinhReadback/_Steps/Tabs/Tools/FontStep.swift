import Foundation

/// R47 (P8-FONT-1, headmate request): the app's own interface is in Menlo. A fresh start with a folder (as
/// R39) and the Settings Hub opened (as R29); then the probe's state says each main control's font family.
/// No focus, no keys. Web pages keep their own fonts: not read here.
enum FontStep {
    static let step = Step(id: "R47", name: "the sidebar, address bar, find bar and Settings Hub are in Menlo",
                           run: run)
    static let controls = ["sidebar row", "folder row", "New Tab", "address bar", "find bar", "Settings Hub"]
    static let wanted = "Menlo"

    /// Each control not in Menlo, with what it shows; a control the probe did not read is "not read".
    static func wrong(_ fonts: [String: String]) -> [String] {
        controls.compactMap { name in fonts[name] == wanted ? nil : "\(name): \(fonts[name] ?? "not read")" }
    }

    static func run(_ app: AppSession) throws -> String {
        _ = try FolderSteps.withFolder(app)
        try HubSteps.openHub(app)
        let state = try app.state()  // an unreachable probe is NOT READ BACK, never a FAIL
        let wrong = wrong(state.fonts)
        try expect(wrong.isEmpty, "not in \(wanted): \(wrong.joined(separator: "; "))")
        return "3 tabs, a folder, the Settings Hub open: \(controls.joined(separator: ", ")) read \(wanted)"
    }
}
