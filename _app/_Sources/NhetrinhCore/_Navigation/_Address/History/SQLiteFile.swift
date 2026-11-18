import Foundation
import SQLite3

// P11-HISTORY (D30): macOS's own SQLite (the system library, no package), used by `HistoryStore` only.

/// A value bound to a `?` of a statement.
enum SQLValue {
    case text(String)
    case real(Double)
    case int(Int)
}

/// One open SQLite file; every call on the thread that made it (the main thread in the app).
final class SQLiteFile {
    enum Failure: Error, Equatable { case sqlite(code: Int32, message: String) }

    private var handle: OpaquePointer?
    /// SQLite copies a bound text at once (SQLITE_TRANSIENT).
    private static let copy = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(path: String) throws {
        let code = sqlite3_open_v2(path, &handle, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil)
        guard code == SQLITE_OK else {
            let failure = Failure.sqlite(code: code, message: handle.map { String(cString: sqlite3_errmsg($0)) } ?? "")
            sqlite3_close_v2(handle)
            throw failure
        }
    }

    deinit { sqlite3_close_v2(handle) }

    /// Run `sql` to its end with `values` bound in order.
    func run(_ sql: String, _ values: [SQLValue] = []) throws {
        try rows(sql, values) { _ in }
    }

    /// Run `sql`; `read` sees each row (`column` reads by index).
    func rows(_ sql: String, _ values: [SQLValue], read: (Row) -> Void) throws {
        var statement: OpaquePointer?
        try check(sqlite3_prepare_v2(handle, sql, -1, &statement, nil))
        defer { sqlite3_finalize(statement) }
        for (index, value) in values.enumerated() { try check(bind(value, at: Int32(index + 1), in: statement)) }
        while true {
            let code = sqlite3_step(statement)
            if code == SQLITE_DONE { return }
            guard code == SQLITE_ROW else { return try check(code) }
            read(Row(statement: statement))
        }
    }

    private func bind(_ value: SQLValue, at index: Int32, in statement: OpaquePointer?) -> Int32 {
        switch value {
        case .text(let text): return sqlite3_bind_text(statement, index, text, -1, Self.copy)
        case .real(let number): return sqlite3_bind_double(statement, index, number)
        case .int(let number): return sqlite3_bind_int64(statement, index, Int64(number))
        }
    }

    private func check(_ code: Int32) throws {
        guard code != SQLITE_OK, code != SQLITE_ROW, code != SQLITE_DONE else { return }
        throw Failure.sqlite(code: code, message: handle.map { String(cString: sqlite3_errmsg($0)) } ?? "")
    }

    /// The current row of a statement.
    struct Row {
        let statement: OpaquePointer?

        func text(_ index: Int32) -> String { sqlite3_column_text(statement, index).map { String(cString: $0) } ?? "" }
        func real(_ index: Int32) -> Double { sqlite3_column_double(statement, index) }
        func int(_ index: Int32) -> Int { Int(sqlite3_column_int64(statement, index)) }
    }
}
