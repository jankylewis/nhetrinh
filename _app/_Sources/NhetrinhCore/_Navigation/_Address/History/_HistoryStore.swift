import Foundation

// P11-HISTORY (D30); tests in Tests/_NhetrinhCoreTests/_Navigation/_Address/History/.

/// The visited pages, `history.sqlite` in the folder it is given (the profile's folder; today the session's,
/// `SessionStore.folder`). One `pages` table, url unique; at most `capacity` rows: past it the lowest score
/// (`Frecency`) goes. The file is the user's alone (0600); deleted rows are overwritten (secure_delete).
public final class HistoryStore {
    public static let fileName = "history.sqlite"
    public static let capacity = 5_000
    /// The dropdown's rows at most.
    public static let shown = 8
    public let fileURL: URL
    let capacity: Int
    let database: SQLiteFile

    public init(folder: URL, capacity: Int = HistoryStore.capacity) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent(Self.fileName)
        self.capacity = capacity
        let owner: [FileAttributeKey: Any] = [.posixPermissions: 0o600]
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: owner)
        }
        try FileManager.default.setAttributes(owner, ofItemAtPath: fileURL.path)  // its -wal and -shm follow it
        database = try SQLiteFile(path: fileURL.path)
        try database.run("PRAGMA secure_delete = ON")
        try database.run("PRAGMA journal_mode = WAL")  // a visit costs no wait for the disk on the main thread
        try database.run("PRAGMA synchronous = NORMAL")
        try database.run("""
            CREATE TABLE IF NOT EXISTS pages (url TEXT PRIMARY KEY, title TEXT NOT NULL, visits INTEGER NOT NULL,
              typed INTEGER NOT NULL, last_visit REAL NOT NULL, words TEXT NOT NULL, bare TEXT NOT NULL)
            """)
        try? forgetSignInSteps()  // best effort: a failure here never keeps the history closed
    }

    /// Sign-in steps an earlier build kept (`HistoryRules.isSignInStep`, headmate 2026-11-19) go; the rest stay.
    func forgetSignInSteps() throws {
        var steps: [String] = []
        try database.rows("SELECT url FROM pages", []) { row in
            if let url = URL(string: row.text(0)), HistoryRules.isSignInStep(url) { steps.append(row.text(0)) }
        }
        for url in steps { try remove(url: url) }
    }

    public var count: Int {
        var found = 0
        try? database.rows("SELECT count(*) FROM pages", []) { found = $0.int(0) }
        return found
    }

    /// One visit of `url` at `date`; `typed`: the user typed or picked it in the address bar. An empty title
    /// keeps the kept one; the last visit is the latest seen.
    public func record(url: String, title: String, typed: Bool, at date: Date) throws {
        try database.run("""
            INSERT INTO pages VALUES (?1, ?2, 1, ?3, ?4, ?5, ?6) ON CONFLICT(url) DO UPDATE SET
              title = CASE WHEN excluded.title <> '' THEN excluded.title ELSE title END,
              words = CASE WHEN excluded.title <> '' THEN excluded.words ELSE words END,
              visits = visits + 1, typed = typed + excluded.typed, last_visit = max(last_visit, excluded.last_visit)
            """, [.text(url), .text(title), .int(typed ? 1 : 0), .real(date.timeIntervalSince1970),
                  .text(HistoryMatch.haystack(url: url, title: title)), .text(HistoryMatch.bare(url))])
        try trim(now: date)
    }

    /// The title WebKit reported after the visit was kept (NT-BUG-029): it fills a row that has none. A row with a
    /// title keeps it, so a page whose title keeps changing writes nothing.
    public func retitle(url: String, title: String) throws {
        guard !title.isEmpty else { return }
        try database.run("UPDATE pages SET title = ?2, words = ?3 WHERE url = ?1 AND title = ''",
                         [.text(url), .text(title), .text(HistoryMatch.haystack(url: url, title: title))])
    }

    /// Past the cap, the lowest scores go (the oldest first among equals).
    func trim(now: Date) throws {
        let extra = count - capacity
        guard extra > 0 else { return }
        try database.run("""
            DELETE FROM pages WHERE url IN
              (SELECT url FROM pages ORDER BY \(Frecency.sql(now: now)) ASC, last_visit ASC LIMIT ?1)
            """, [.int(extra)])
    }

    public func entry(url: String) throws -> HistoryEntry? {
        var found: HistoryEntry?
        try database.rows("SELECT url, title, visits, typed, last_visit FROM pages WHERE url = ?1", [.text(url)]) {
            found = Self.entry($0)
        }
        return found
    }

    /// ⇧⌫ on a dropdown row: that page goes.
    public func remove(url: String) throws {
        try database.run("DELETE FROM pages WHERE url = ?1", [.text(url)])
    }

    /// Clear All: every page goes, the write-ahead log too.
    public func clear() throws {
        try database.run("DELETE FROM pages")
        try database.run("PRAGMA wal_checkpoint(TRUNCATE)")
    }

    /// The pages whose url or title holds every word of `typed`: a host prefix first, then the best score, then
    /// the latest visit; at most `limit`. Typed text only goes in as bound values.
    public func suggestions(for typed: String, now: Date, limit: Int = HistoryStore.shown) throws -> [HistoryEntry] {
        let words = Array(HistoryMatch.words(typed).prefix(8))
        guard !words.isEmpty else { return [] }
        let filter = words.indices.map { "instr(words, ?\($0 + 2)) > 0" }.joined(separator: " AND ")
        let prefix = HistoryMatch.prefixKey(typed)
        let first = prefix == nil ? "(1 = 0)" : "instr(bare, ?\(words.count + 2)) = 1"
        let sql = "SELECT url, title, visits, typed, last_visit FROM pages WHERE \(filter) "
            + "ORDER BY \(first) DESC, \(Frecency.sql(now: now)) DESC, last_visit DESC LIMIT ?1"
        let values = [SQLValue.int(limit)] + words.map(SQLValue.text) + (prefix.map { [SQLValue.text($0)] } ?? [])
        var found: [HistoryEntry] = []
        try database.rows(sql, values) { found.append(Self.entry($0)) }
        return found
    }

    private static func entry(_ row: SQLiteFile.Row) -> HistoryEntry {
        HistoryEntry(url: row.text(0), title: row.text(1), visits: row.int(2), typed: row.int(3),
                     lastVisit: Date(timeIntervalSince1970: row.real(4)))
    }
}
