import Foundation
import Testing
@testable import NhetrinhReadback

// R9-R12 use the readback's own local pages. The server is tested here, with no app.

@Test(arguments: [("/page/1", "200 OK", "nhetrinh test 1"), ("/page/12", "200 OK", "nhetrinh test 12"),
                  ("/play", "200 OK", TestPageContent.waitingTitle), ("/page/x", "404 Not Found", ""),
                  ("/", "404 Not Found", "")])
func testPageReplies(path: String, status: String, title: String) {
    let reply = TestPageContent.reply(path: path)
    #expect(reply.status == status)
    let body = String(decoding: reply.body, as: UTF8.self)
    #expect(title.isEmpty || body.contains("<title>\(title)</title>"))
}

/// The audio page sets the title the readback waits for, and plays the silence in a loop.
@Test func playPageSaysWhenItPlays() {
    let body = String(decoding: TestPageContent.reply(path: "/play").body, as: UTF8.self)
    #expect(body.contains("'\(TestPageContent.playingTitle)'") && body.contains("src=\"/silence.wav\""))
    #expect(body.contains("autoplay") && body.contains("loop"))
}

/// A real WAV head, and nothing but zero samples: nothing is heard on the shared machine.
@Test func silenceIsAWaveOfZeros() {
    let wav = TestPageContent.silence
    #expect(wav.prefix(4) == Data("RIFF".utf8) && wav.subdata(in: 8..<16) == Data("WAVEfmt ".utf8))
    #expect(wav.count == 44 + 32_000)
    #expect(wav.dropFirst(44).allSatisfy { $0 == 0 })
}

@Test(arguments: [
    (header: "bytes=0-1", size: 10, range: [0, 1]), ("bytes=4-", 10, [4, 9]), ("bytes=8-99", 10, [8, 9]),
    ("bytes=10-", 10, []), ("bytes=5-2", 10, []), ("bytes=-5", 10, []), ("items=0-1", 10, []), (nil, 10, []),
])
func byteRanges(header: String?, size: Int, range: [Int]) {
    let found = TestPageContent.byteRange(header, size: size)
    #expect(found.map { [$0.0, $0.1] } ?? [] == range)
}

@Test func rangedReplyIsPartialContent() {
    let reply = TestPageContent.ranged(Data([1, 2, 3, 4]), type: "audio/wav", range: "bytes=1-2")
    #expect(reply.status == "206 Partial Content" && reply.body == Data([2, 3]))
    #expect(reply.headers.contains("Content-Range: bytes 1-2/4"))
}

@Test(arguments: [("GET /page/2?x=1 HTTP/1.1\r\nRange: bytes=0-1\r\n\r\n", "/page/2", "bytes=0-1"),
                  ("GET /play HTTP/1.1\r\nrange:  bytes=3-\r\n\r\n", "/play", "bytes=3-"),
                  ("GET /play HTTP/1.1\r\n\r\n", "/play", nil), ("", "", nil)])
func requestHeadIsRead(head: String, path: String, range: String?) {
    #expect(TestPages.path(head) == path)
    #expect(TestPages.header("Range", in: head) == range)
}

/// The live server, over 127.0.0.1: a page, and the audio by range as WebKit asks for it.
@Test func liveServerAnswers() async throws {
    let pages = try TestPages.shared.get()
    let page = try #require(URL(string: pages.url("/page/3")))
    let (body, response) = try await URLSession.shared.data(from: page)
    #expect((response as? HTTPURLResponse)?.statusCode == 200)
    #expect(String(decoding: body, as: UTF8.self).contains("<title>nhetrinh test 3</title>"))
    var request = URLRequest(url: try #require(URL(string: pages.url("/silence.wav"))))
    request.setValue("bytes=0-3", forHTTPHeaderField: "Range")
    let (audio, ranged) = try await URLSession.shared.data(for: request)
    #expect((ranged as? HTTPURLResponse)?.statusCode == 206 && audio == Data("RIFF".utf8))
}

@Test func lifecycleStepsAreR9ToR12() {
    #expect(LifecycleSteps.all.map(\.id) == ["R9", "R10", "R11", "R12"])
}
