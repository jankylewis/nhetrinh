import Foundation

/// The readback's end: one connection per request, one line each way, bounded by a timeout.
public enum ProbeClient {
    public static func send(_ request: ProbeRequest, to path: String,
                            timeout: TimeInterval = 5) throws -> ProbeResponse {
        let reply = try exchange(try ProbeCodec.encode(request), with: path, timeout: timeout)
        return try ProbeCodec.decodeResponse(reply)
    }

    /// Send one raw line and return the raw answer line.
    public static func exchange(_ line: String, with path: String, timeout: TimeInterval = 5) throws -> String {
        let socket = try ProbeSocket.make()
        defer { close(socket) }
        ProbeSocket.setTimeout(socket, timeout)
        guard try ProbeSocket.withAddress(path, { connect(socket, $0, $1) }) == 0 else {
            throw ProbeError.system("connect", errno)
        }
        try ProbeSocket.writeLine(socket, line)
        guard let reply = try ProbeSocket.readLine(socket) else { throw ProbeError.noAnswer }
        return reply
    }
}
