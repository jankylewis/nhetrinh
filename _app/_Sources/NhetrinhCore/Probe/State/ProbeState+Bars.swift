import Foundation

/// The probe's fields of the sidebar footer's downloads (P5) and the address bar's dropdown (P11-HISTORY, R54),
/// as the wire carries them.
extension ProbeState {
    var barsObject: [String: Any] {
        var object: [String: Any] = ["downloads": downloads, "downloadStates": downloadStates, "revealed": revealed,
                                     "suggestions": suggestions]
        if let suggestionChosen { object["suggestionChosen"] = suggestionChosen }
        return object
    }

    /// A field that is missing or of another type keeps its default.
    mutating func readBars(_ object: [String: Any]) {
        downloads = object["downloads"] as? [String] ?? []
        downloadStates = object["downloadStates"] as? [String] ?? []
        revealed = object["revealed"] as? [String] ?? []
        suggestions = object["suggestions"] as? [String] ?? []
        suggestionChosen = object["suggestionChosen"] as? Int
    }
}
