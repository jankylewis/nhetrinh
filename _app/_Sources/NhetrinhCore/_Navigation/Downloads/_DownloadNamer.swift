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

    /// Whether `name` can be written in `folder`: the file is made empty and removed at once. macOS asks
    /// for ~/Downloads on the thread that first writes there, so the app calls this off the main thread.
    public static func canWrite(_ name: String, in folder: URL) -> Bool {
        let path = folder.appendingPathComponent(name).path
        let file = open(path, O_WRONLY | O_CREAT | O_EXCL, 0o600)  // never an existing file
        guard file >= 0 else { return false }
        close(file)
        return unlink(path) == 0
    }

    /// The extension of a download not yet complete (F1, F6): `a.pdf.download` until it is `a.pdf`.
    public static let partialExtension = ".download"

    public static func partial(_ name: String) -> String { name + partialExtension }

    /// One key for every spelling ~/Downloads (APFS, by default) takes for the same file: case and Unicode
    /// normalization ignored (F8).
    public static func key(_ name: String) -> String { name.precomposedStringWithCanonicalMapping.lowercased() }

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

    /// The site's name without folders, `:`, control characters and line breaks (F4: U+2028, U+2029 too);
    /// leading dots go (F10: no hidden file in ~/Downloads). A name of only dots or spaces gives `fallback`.
    public static func clean(_ suggested: String) -> String {
        let last = suggested.split(separator: "/").last.map(String.init) ?? ""
        let dropped = CharacterSet.controlCharacters.union(.newlines)
        let kept = last.unicodeScalars.filter { !dropped.contains($0) }
        let name = String(String.UnicodeScalarView(kept)).replacingOccurrences(of: ":", with: "-")
        let visible = name.drop { $0 == "." || $0 == " " }.trimmingCharacters(in: .whitespaces)
        return visible.isEmpty ? fallback : visible
    }
}
