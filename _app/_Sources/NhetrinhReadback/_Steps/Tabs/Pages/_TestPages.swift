import Foundation

/// The readback's local HTTP server for R9-R26: 127.0.0.1 only, a port the system picks (or a given
/// one, R23), alive while the readback runs. Each connection gets one reply (`TestPageContent`), then is closed.
final class TestPages {
    /// Started on first use; a failure to start makes the steps NOT READ BACK.
    static let shared: Result<TestPages, Error> = Result { try TestPages() }

    let port: UInt16

    init(port wanted: UInt16 = 0) throws {
        let (listener, port) = try Self.listen(port: wanted)
        self.port = port
        Thread.detachNewThread { Self.serve(listener) }
    }

    /// A port nobody listens on now: bound once by the system's choice, then closed (R23).
    static func freePort() throws -> UInt16 {
        let (listener, port) = try listen(port: 0)
        close(listener)
        return port
    }

    private static func listen(port wanted: UInt16) throws -> (Int32, UInt16) {
        let listener = socket(AF_INET, SOCK_STREAM, 0)
        guard listener >= 0 else { throw StepError.cannotDrive("test pages: no socket (errno \(errno))") }
        var on: Int32 = 1
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size))
        var address = sockaddr_in()
        address.sin_port = wanted.bigEndian
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(listener, $0, length) == 0 && getsockname(listener, $0, &length) == 0
            }
        }
        guard bound, Darwin.listen(listener, 16) == 0 else {
            let code = errno
            close(listener)
            throw StepError.cannotDrive("test pages: cannot listen on 127.0.0.1 (errno \(code))")
        }
        return (listener, UInt16(bigEndian: address.sin_port))
    }

    /// The address of `path` on this server, as typed in the address bar.
    func url(_ path: String) -> String { "http://127.0.0.1:\(port)\(path)" }

    private static func serve(_ listener: Int32) {
        while true {
            let peer = accept(listener, nil, nil)
            if peer < 0 {
                if errno == EINTR { continue }
                return
            }
            DispatchQueue.global().async { answer(peer) }
        }
    }

    /// Read the request head (2 s at most: WebKit may open a connection it never uses), reply, close.
    private static func answer(_ peer: Int32) {
        defer { close(peer) }
        var on: Int32 = 1
        setsockopt(peer, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        var timeout = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(peer, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
        var buffer = [UInt8](repeating: 0, count: 8192)
        let count = read(peer, &buffer, buffer.count)
        guard count > 0 else { return }
        let head = String(decoding: buffer.prefix(count), as: UTF8.self)
        let reply = TestPageContent.reply(path: path(head), range: header("Range", in: head),
                                          authorization: header("Authorization", in: head))
        if reply.delay > 0 { Thread.sleep(forTimeInterval: reply.delay) }
        let data = bytes(reply)
        guard reply.pace > 0 else { return _ = write(peer, data) }
        let part = 65_536
        for start in stride(from: 0, to: data.count, by: part) {  // ends when the app closes the connection
            guard write(peer, data.subdata(in: start..<min(start + part, data.count))) else { return }
            Thread.sleep(forTimeInterval: reply.pace)
        }
    }

    static func path(_ head: String) -> String {
        let words = head.split(separator: "\r\n").first?.split(separator: " ") ?? []
        return words.count >= 2 ? String(words[1].split(separator: "?").first ?? "") : ""
    }

    static func header(_ name: String, in head: String) -> String? {
        let prefix = name.lowercased() + ":"
        let line = head.split(separator: "\r\n").first { $0.lowercased().hasPrefix(prefix) }
        return line.map { $0.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces) }
    }

    static func bytes(_ reply: TestPageContent.Reply) -> Data {
        let lines = ["HTTP/1.1 \(reply.status)", "Content-Type: \(reply.type)",
                     "Content-Length: \(reply.body.count)", "Connection: close", "Cache-Control: no-store"]
            + reply.headers
        return Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8) + reply.body
    }

    /// Whether every byte went out.
    @discardableResult
    private static func write(_ peer: Int32, _ data: Data) -> Bool {
        data.withUnsafeBytes { raw in
            var sent = 0
            while sent < raw.count, let base = raw.baseAddress {
                let written = Darwin.write(peer, base + sent, raw.count - sent)
                if written <= 0 { return false }
                sent += written
            }
            return true
        }
    }
}
