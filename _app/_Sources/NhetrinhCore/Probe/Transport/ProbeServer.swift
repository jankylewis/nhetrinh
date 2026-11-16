import Foundation

/// The app's end (D23): a Unix socket in a folder only its owner can enter (0700, socket 0600),
/// never a TCP port. It answers one line per connection, on `queue`, and only peers of its own
/// user. It exists only when the app was started with `NHT_READBACK=1`.
public final class ProbeServer {
    public let path: String
    private let folder: String
    private let listener: Int32
    private let source: DispatchSourceRead
    private let handle: (ProbeRequest) -> ProbeResponse
    /// A peer gets this long to send its line; the queue is the app's main queue.
    static let peerTimeout: TimeInterval = 1

    public init(folder: String, queue: DispatchQueue,
                handle: @escaping (ProbeRequest) -> ProbeResponse) throws {
        self.folder = folder
        path = folder + "/probe.sock"
        self.handle = handle
        try Self.makePrivateFolder(folder)
        listener = try Self.listen(at: path)
        source = DispatchSource.makeReadSource(fileDescriptor: listener, queue: queue)
        let listener = listener
        source.setCancelHandler { close(listener) }
        source.setEventHandler { [weak self] in self?.acceptOne() }
        source.resume()
    }

    deinit { stop() }

    /// Close the socket and remove its folder.
    public func stop() {
        guard !source.isCancelled else { return }
        source.cancel()
        try? FileManager.default.removeItem(atPath: folder)
    }

    private static func makePrivateFolder(_ folder: String) throws {
        let manager = FileManager.default
        try? manager.removeItem(atPath: folder)  // a folder left by an earlier process of this pid
        try manager.createDirectory(atPath: folder, withIntermediateDirectories: false,
                                    attributes: [.posixPermissions: 0o700])
    }

    private static func listen(at path: String) throws -> Int32 {
        let socket = try ProbeSocket.make()
        guard try ProbeSocket.withAddress(path, { bind(socket, $0, $1) }) == 0 else {
            let code = errno
            close(socket)
            throw ProbeError.system("bind", code)
        }
        guard chmod(path, 0o600) == 0, Darwin.listen(socket, 4) == 0 else {
            let code = errno
            close(socket)
            throw ProbeError.system("listen", code)
        }
        return socket
    }

    private func acceptOne() {
        let peer = accept(listener, nil, nil)
        guard peer >= 0 else { return }
        defer { close(peer) }
        var on: Int32 = 1
        setsockopt(peer, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        guard Self.isOwnUser(peer) else { return }
        ProbeSocket.setTimeout(peer, Self.peerTimeout)
        guard let line = try? ProbeSocket.readLine(peer) else { return }
        let response = (try? ProbeCodec.decodeRequest(line)).map(handle) ?? .failed("malformed request")
        guard let reply = try? ProbeCodec.encode(response) else { return }
        try? ProbeSocket.writeLine(peer, reply)
    }

    private static func isOwnUser(_ peer: Int32) -> Bool {
        var uid: uid_t = 0, gid: gid_t = 0
        return getpeereid(peer, &uid, &gid) == 0 && uid == getuid()
    }
}
