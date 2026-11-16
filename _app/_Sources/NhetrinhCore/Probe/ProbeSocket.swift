import Foundation

/// Why a probe exchange did not happen. The text never holds a path (public reports, D23).
public enum ProbeError: Error, Equatable, CustomStringConvertible {
    case system(String, Int32)
    case pathTooLong
    case noAnswer
    case unexpected(String)

    public var description: String {
        switch self {
        case .system(let call, let code): return "\(call) failed: \(String(cString: strerror(code)))"
        case .pathTooLong: return "the socket path is longer than \(ProbePath.maxLength) bytes"
        case .noAnswer: return "the probe closed the connection without an answer"
        case .unexpected(let what): return "unexpected answer: \(what)"
        }
    }
}

/// The Unix-socket plumbing both ends share: an address, timeouts, one line in, one line out.
enum ProbeSocket {
    /// The longest line either end reads; a longer one is cut and then fails to decode.
    static let maxLine = 1 << 20

    static func make() throws -> Int32 {
        let socket = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        guard socket >= 0 else { throw ProbeError.system("socket", errno) }
        var on: Int32 = 1
        // A peer that went away must give EPIPE, never a SIGPIPE that ends the app.
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        return socket
    }

    /// Run `call` with `path` as a socket address (bind or connect).
    static func withAddress(_ path: String, _ call: (UnsafePointer<sockaddr>, socklen_t) -> Int32) throws -> Int32 {
        let bytes = Array(path.utf8)
        guard bytes.count <= ProbePath.maxLength else { throw ProbeError.pathTooLong }
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        address.sun_len = UInt8(MemoryLayout<sockaddr_un>.size)
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }
        return withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                call($0, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
    }

    static func setTimeout(_ socket: Int32, _ seconds: TimeInterval) {
        var limit = timeval(tv_sec: Int(seconds), tv_usec: Int32((seconds - floor(seconds)) * 1_000_000))
        let size = socklen_t(MemoryLayout<timeval>.size)
        setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &limit, size)
        setsockopt(socket, SOL_SOCKET, SO_SNDTIMEO, &limit, size)
    }

    /// Read up to the first newline (not included). Throws on a timeout or an error; nil at once on EOF.
    /// With a `deadline`, the whole line must arrive before it: `SO_RCVTIMEO` alone bounds one `read`,
    /// so a peer sending a byte at a time would hold the reader for as long as it likes (P0-REV-PROBE).
    static func readLine(_ socket: Int32, by deadline: Date? = nil) throws -> String? {
        var line: [UInt8] = []
        var byte: UInt8 = 0
        while line.count < maxLine {
            if let deadline { try receiveTimeout(socket, until: deadline) }
            let count = read(socket, &byte, 1)
            if count < 0 { throw ProbeError.system("read", errno) }
            if count == 0 { return line.isEmpty ? nil : String(decoding: line, as: UTF8.self) }
            if byte == UInt8(ascii: "\n") { break }
            line.append(byte)
        }
        return String(decoding: line, as: UTF8.self)
    }

    /// Bound the next `read` by the time left before `deadline`; none left is a timeout.
    /// A zero `timeval` would mean "no limit", so the least is 1 ms.
    static func receiveTimeout(_ socket: Int32, until deadline: Date) throws {
        let left = deadline.timeIntervalSinceNow
        guard left > 0 else { throw ProbeError.system("read", ETIMEDOUT) }
        let bounded = max(left, 0.001)
        var limit = timeval(tv_sec: Int(bounded), tv_usec: Int32((bounded - floor(bounded)) * 1_000_000))
        setsockopt(socket, SOL_SOCKET, SO_RCVTIMEO, &limit, socklen_t(MemoryLayout<timeval>.size))
    }

    static func writeLine(_ socket: Int32, _ text: String) throws {
        let bytes = Array((text + "\n").utf8)
        var sent = 0
        while sent < bytes.count {
            let count = bytes[sent...].withUnsafeBytes { write(socket, $0.baseAddress, $0.count) }
            guard count > 0 else { throw ProbeError.system("write", errno) }
            sent += count
        }
    }
}
