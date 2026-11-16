import os

/// The app's loggers. Every failure path writes a line here; nothing fails in silence.
/// Read them with: log stream --predicate 'subsystem == "io.github.jankylewis.nhetrinh"'
enum Log {
    static let app = Logger(subsystem: "io.github.jankylewis.nhetrinh", category: "app")
    static let web = Logger(subsystem: "io.github.jankylewis.nhetrinh", category: "web")
}
