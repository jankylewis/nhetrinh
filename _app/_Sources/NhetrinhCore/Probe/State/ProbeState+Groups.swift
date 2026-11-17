import Foundation

/// The probe's P7 folder fields and P8-GROUPS-1 group fields (R39 to R43, R47, R49), as the wire carries them.
extension ProbeState {
    var groupObject: [String: Any] {
        ["folders": folders, "folderTabs": folderTabs, "collapsedFolders": collapsedFolders,
         "groupPaths": groupPaths, "groupCounts": groupCounts, "rowLevels": rowLevels, "tabTitles": tabTitles,
         "groupRefusal": groupRefusal]
    }

    /// A field that is missing or of another type keeps its default.
    mutating func readGroups(_ object: [String: Any]) {
        folders = object["folders"] as? [String] ?? []
        folderTabs = object["folderTabs"] as? [[String]] ?? []
        collapsedFolders = object["collapsedFolders"] as? [Bool] ?? []
        groupPaths = object["groupPaths"] as? [String] ?? []
        groupCounts = object["groupCounts"] as? [Int] ?? []
        rowLevels = object["rowLevels"] as? [Int] ?? []
        tabTitles = object["tabTitles"] as? [String] ?? []
        groupRefusal = object["groupRefusal"] as? String ?? ""
    }
}
