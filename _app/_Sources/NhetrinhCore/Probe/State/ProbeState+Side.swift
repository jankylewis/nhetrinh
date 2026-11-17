import Foundation

/// The probe's P8-SIDE-1 fields (R50), as the wire carries them.
extension ProbeState {
    var sideObject: [String: Any] {
        ["sidebarSide": sidebarSide, "toggleSymbol": toggleSymbol, "sidebarFrame": sidebarFrame, "webFrame": webFrame]
    }

    /// A field that is missing or of another type keeps its default.
    mutating func readSide(_ object: [String: Any]) {
        sidebarSide = object["sidebarSide"] as? String ?? ""
        toggleSymbol = object["toggleSymbol"] as? String ?? ""
        sidebarFrame = object["sidebarFrame"] as? [Double] ?? []
        webFrame = object["webFrame"] as? [Double] ?? []
    }
}
