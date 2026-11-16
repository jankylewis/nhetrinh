import Foundation

/// What the readback's local test server answers (R9-R12): never a site on the Internet.
///   /page/<n>      a page titled "nhetrinh test <n>"
///   /play          a page that plays /silence.wav in a loop; its title says when it plays
///   /silence.wav   2 s of silence (digital zero: nothing is heard on the shared machine)
enum TestPageContent {
    struct Reply: Equatable {
        var status = "200 OK"
        var type = "text/html; charset=utf-8"
        var headers: [String] = []
        var body = Data()
    }

    static let waitingTitle = "audio test: waiting"
    static let playingTitle = "audio test: playing"

    static func title(page: Int) -> String { "nhetrinh test \(page)" }

    /// The reply to `GET path` with an optional `Range: bytes=a-b` (WebKit asks media by range).
    static func reply(path: String, range: String? = nil) -> Reply {
        if path.hasPrefix("/page/"), let page = Int(path.dropFirst(6)) {
            return html("<title>\(title(page: page))</title><p>nhetrinh readback test page \(page)</p>")
        }
        switch path {
        case "/play": return html(playPage)
        case "/silence.wav": return ranged(silence, type: "audio/wav", range: range)
        default: return Reply(status: "404 Not Found", type: "text/plain", body: Data("not found".utf8))
        }
    }

    private static let playPage = """
        <title>\(waitingTitle)</title><audio id="a" src="/silence.wav" autoplay loop></audio>
        <script>
        a.addEventListener('playing', () => { document.title = '\(playingTitle)' })
        a.addEventListener('pause', () => { document.title = 'audio test: paused' })
        </script>
        """

    private static func html(_ body: String) -> Reply {
        Reply(body: Data(("<!doctype html><meta charset=\"utf-8\">" + body).utf8))
    }

    /// The whole body, or the asked bytes as 206 Partial Content.
    static func ranged(_ data: Data, type: String, range: String?) -> Reply {
        var reply = Reply(type: type, headers: ["Accept-Ranges: bytes"], body: data)
        guard let (first, last) = byteRange(range, size: data.count) else { return reply }
        reply.status = "206 Partial Content"
        reply.headers.append("Content-Range: bytes \(first)-\(last)/\(data.count)")
        reply.body = data.subdata(in: first..<(last + 1))
        return reply
    }

    /// `bytes=a-b` or `bytes=a-` inside `size`; nil for no range or one this server does not serve.
    static func byteRange(_ header: String?, size: Int) -> (Int, Int)? {
        guard let header, header.hasPrefix("bytes="), size > 0 else { return nil }
        let parts = header.dropFirst(6).split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 2, let first = Int(parts[0]), first < size else { return nil }
        let last = parts[1].isEmpty ? size - 1 : min(Int(parts[1]) ?? -1, size - 1)
        return last >= first ? (first, last) : nil
    }

    /// A WAV file: 8 kHz, 16-bit, mono, 2 s of zero samples.
    static let silence: Data = {
        let rate: UInt32 = 8000, samples = 16_000
        let dataSize = UInt32(samples * 2)
        var data = Data("RIFF".utf8)
        append(&data, 36 + dataSize)
        data.append(Data("WAVEfmt ".utf8))
        append(&data, UInt32(16))
        append(&data, UInt16(1))  // PCM
        append(&data, UInt16(1))  // mono
        append(&data, rate)
        append(&data, rate * 2)  // bytes per second
        append(&data, UInt16(2))  // bytes per frame
        append(&data, UInt16(16))  // bits per sample
        data.append(Data("data".utf8))
        append(&data, dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }()

    private static func append<T: FixedWidthInteger>(_ data: inout Data, _ value: T) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
