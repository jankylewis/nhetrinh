import Foundation

/// The readback's local HTTP server for R9-R12: 127.0.0.1 only, a port the system picks, alive
/// while the readback runs. Each connection gets one reply (`TestPageContent`), then is closed.
final class TestPages {
    /// Started on first use; a failure to start makes the steps NOT READ BACK.
    static let shared: Result<TestPages, Error> = Result { try TestPages() }

    let port: UInt16

    init() throws {
        let listener = socket(AF_INET, SOCK_STREAM, 0)
        guard listener >= 0 else { throw StepError.cannotDrive("test pages: no socket (errno \(errno))") }
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(listener, $0, length) == 0 && getsockname(listener, $0, &length) == 0
            }
        }
        guard bound, listen(listener, 16) == 0 else {
            let code = errno
            close(listener)
            throw StepError.cannotDrive("test pages: cannot listen on 127.0.0.1 (errno \(code))")
        }
        port = UInt16(bigEndian: address.sin_port)
        Thread.detachNewThread { Self.serve(listener) }
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
        let reply = TestPageContent.reply(path: path(head), range: header("Range", in: head))
        write(peer, bytes(reply))
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

    private static func write(_ peer: Int32, _ data: Data) {
        data.withUnsafeBytes { raw in
            var sent = 0
            while sent < raw.count, let base = raw.baseAddress {
                let written = Darwin.write(peer, base + sent, raw.count - sent)
                if written <= 0 { return }
                sent += written
            }
        }
    }
}
