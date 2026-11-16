import Foundation

// P5 (hubs/product/plan/M2_REAL_SITES_WORK.md); tests in Downloads/_DownloadNamerTests.swift.

/// The name a download gets in ~/Downloads: the site's name made safe, and the first free one of
/// `a.pdf`, `a (1).pdf`, `a (2).pdf`… A file there is never replaced.
public enum DownloadNamer {
    /// A file name on APFS is at most 255 bytes of UTF-8.
    public static let maxBytes = 255
    /// The name used when the site gives none that is usable.
    public static let fallback = "download"
    /// Clashes tried before giving up (nil: no free name).
    public static let maxTries = 9_999

    /// The first name `isTaken` does not hold, or nil past `maxTries` clashes.
    public static func freeName(_ suggested: String, isTaken: (String) -> Bool) -> String? {
        let name = clean(suggested)
        return (0...maxTries).lazy.map { candidate(name, number: $0) }.first { !isTaken($0) }
    }

    /// Clash `number` of `suggested` (0: the name itself), cut to `maxBytes`.
    public static func candidate(_ suggested: String, number: Int) -> String {
        var (base, ext) = split(suggested)
        if ext.utf8.count > maxBytes / 2 { (base, ext) = (suggested, "") }  // not an extension: a long name
        let tail = (number > 0 ? " (\(number))" : "") + ext
        let room = maxBytes - tail.utf8.count
        while base.utf8.count > room { base.removeLast() }
        return base + tail
    }

    /// `a.tar.gz` -> (`a.tar`, `.gz`); `.env` and `README` have no extension; `a.` neither.
    static func split(_ name: String) -> (String, String) {
        guard let dot = name.lastIndex(of: "."), dot != name.startIndex,
              name.index(after: dot) != name.endIndex else { return (name, "") }
        return (String(name[..<dot]), String(name[dot...]))
    }

    /// The site's name without folders, `:` and control characters; a name of only dots or spaces
    /// gives `fallback`. A dot file keeps its dot (it has no extension).
    public static func clean(_ suggested: String) -> String {
        let last = suggested.split(separator: "/").last.map(String.init) ?? ""
        let kept = last.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        let name = String(String.UnicodeScalarView(kept)).replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespaces)
        return name.allSatisfy { $0 == "." || $0 == " " } ? fallback : name
    }
}
