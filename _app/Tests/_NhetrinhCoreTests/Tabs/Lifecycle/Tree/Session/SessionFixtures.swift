import Foundation

// P7-PREP-1: session files as they are on disk. Version 1 is what `SessionStore.save` writes since P1
// (JSONEncoder, keys sorted, slashes escaped); version 2 is the P7 schema these tests fix.

enum SessionFixtures {
    /// 3 tabs, the 2nd selected, sidebar 240.5 pt, collapsed.
    static let v1ThreeTabs = #"""
        {"collapsed":true,"selectedIndex":1,"sidebarWidth":240.5,"tabs":[\#
        {"title":"a","url":"https:\/\/a.example\/"},{"title":"b","url":"https:\/\/b.example\/"},\#
        {"title":"c","url":"https:\/\/c.example\/"}],"version":1}
        """#

    /// A hand-edited file: the selection points past the 2 tabs.
    static let v1SelectedPastTheEnd = #"""
        {"collapsed":false,"selectedIndex":7,"sidebarWidth":220,"tabs":[\#
        {"title":"a","url":"https:\/\/a.example\/"},{"title":"b","url":"https:\/\/b.example\/"}],"version":1}
        """#

    static let v1NoTabs = #"{"collapsed":false,"selectedIndex":0,"sidebarWidth":220,"tabs":[],"version":1}"#

    /// a | work (b, c), collapsed | d; c selected.
    static let v2Folders = #"""
        {"collapsed":false,"items":[{"tab":{"title":"a","url":"https:\/\/a.example\/"}},\#
        {"folder":{"collapsed":true,"name":"work","tabs":[{"title":"b","url":"https:\/\/b.example\/"},\#
        {"title":"c","url":"https:\/\/c.example\/"}]}},{"tab":{"title":"d","url":"https:\/\/d.example\/"}}],\#
        "selected":{"item":1,"tab":1},"sidebarWidth":220,"version":2}
        """#

    /// P8-GROUPS-1, version 3: a | Work (b | FE, collapsed (c)); c selected. What `encode` writes.
    static let v3Nested = #"""
        {"collapsed":false,"items":[{"tab":{"title":"a","url":"https:\/\/a.example\/"}},\#
        {"folder":{"collapsed":false,"items":[{"tab":{"title":"b","url":"https:\/\/b.example\/"}},\#
        {"folder":{"collapsed":true,"items":[{"tab":{"title":"c","url":"https:\/\/c.example\/"}}],"name":"FE"}}],\#
        "name":"Work"}}],"selected":[1,1,0],"sidebarWidth":220,"version":3}
        """#

    /// Version 3, 5 group levels: one too many.
    static let v3FiveLevels = #"""
        {"collapsed":false,"items":[{"folder":{"collapsed":false,"name":"1","items":[{"folder":{"collapsed":false,\#
        "name":"2","items":[{"folder":{"collapsed":false,"name":"3","items":[{"folder":{"collapsed":false,"name":"4",\#
        "items":[{"folder":{"collapsed":false,"name":"5","items":[]}}]}}]}}]}}]}}],"selected":[0],\#
        "sidebarWidth":220,"version":3}
        """#

    /// Files version 2 must refuse: one level only, an unknown item, a newer version, a cut file.
    static let bad: [(name: String, text: String)] = [
        ("a folder inside a folder", #"""
            {"collapsed":false,"items":[{"folder":{"collapsed":false,"name":"outer","tabs":[\#
            {"folder":{"collapsed":false,"name":"inner","tabs":[]}}]}}],\#
            "selected":{"item":0},"sidebarWidth":220,"version":2}
            """#),
        ("an item that is neither a tab nor a folder", #"""
            {"collapsed":false,"items":[{"window":{}}],"selected":{"item":0},"sidebarWidth":220,"version":2}
            """#),
        ("version 4", #"{"collapsed":false,"items":[],"selected":[0],"sidebarWidth":220,"version":4}"#),
        ("version 2 cut short", #"{"collapsed":false,"items":[{"tab":"#),
        ("version 3, 5 group levels", v3FiveLevels),
        ("version 3, an empty selected path",
         #"{"collapsed":false,"items":[],"selected":[],"sidebarWidth":220,"version":3}"#),
    ]
}
