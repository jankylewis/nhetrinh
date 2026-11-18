import AppKit
import NhetrinhCore
import Testing
import Network
import WebKit
@testable import Nhetrinh

// P5-REVIEW (nhetrinh_wt/REVIEW_P5.md): `Downloads` driven by real WKDownloads. The bytes come from a
// loopback server of this test (127.0.0.1), never from the network; the folder is a new temporary one.

/// A loopback HTTP server of this test: `/slow` sends 10 of 1000 bytes and never ends, `/fast` all 1000.
/// Both are `race.txt` attachments. 127.0.0.1 only; nothing goes to the network.
final class LoopbackServer {
    private let listener: NWListener
    private var held: [NWConnection] = []
    private(set) var port: UInt16 = 0

    init() throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters)
        listener.newConnectionHandler = { [weak self] connection in self?.serve(connection) }
        listener.start(queue: .main)
    }

    func waitReady() async -> Bool {
        for _ in 0..<50 where (listener.port?.rawValue ?? 0) == 0 { try? await Task.sleep(nanoseconds: 100_000_000) }
        port = listener.port?.rawValue ?? 0
        return port != 0
    }

    private func serve(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, _ in
            let slow = String(decoding: data ?? Data(), as: UTF8.self).hasPrefix("GET /slow")
            let head = "HTTP/1.1 200 OK\r\nContent-Type: application/octet-stream\r\nContent-Length: 1000\r\n"
                + "Content-Disposition: attachment; filename=\"race.txt\"\r\nConnection: close\r\n\r\n"
            let body = Data(repeating: 65, count: slow ? 10 : 1000)
            connection.send(content: Data(head.utf8) + body, completion: .contentProcessed { _ in
                if !slow { connection.cancel() }
            })
            if slow { self?.held.append(connection) }
        }
    }

    func stop() {
        held.forEach { $0.cancel() }
        listener.cancel()
    }
}

/// Every response downloads; every download goes to `downloads`.
final class DownloadingPages: NSObject, WKNavigationDelegate {
    let downloads: Downloads

    init(_ downloads: Downloads) { self.downloads = downloads }

    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        downloads.adopt(download)
    }
}

/// The harness of the download tests: a page that downloads, a load from the server, a wait, a folder.
@MainActor
func downloadPage(_ pages: DownloadingPages) -> WKWebView {
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .nonPersistent()
    let webView = WKWebView(frame: .zero, configuration: config)
    webView.navigationDelegate = pages
    return webView
}

@MainActor
func load(_ path: String, from server: LoopbackServer, in webView: WKWebView) {
    if let url = URL(string: "http://127.0.0.1:\(server.port)/\(path)") { webView.load(URLRequest(url: url)) }
}

@MainActor
func eventually(_ seconds: Double = 10, _ done: () -> Bool) async -> Bool {
    for _ in 0..<Int(seconds * 10) where !done() { try? await Task.sleep(nanoseconds: 100_000_000) }
    return done()
}

func downloadFolder() throws -> URL {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent("nhetrinh-race-\(UUID())")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
}

@MainActor
struct DownloadRaceTests {
    /// Cancel a running race.txt, then download race.txt again at once: the new file must stay. Red on
    /// e7dccf9 (P5-REVIEW F1): the cancel freed the name and removed "its" path once more 0.5 s later.
    @Test func aCancelNeverRemovesTheNextDownloadsFile() async throws {
        let folder = try downloadFolder()
        let server = try LoopbackServer()
        defer {
            server.stop()
            try? FileManager.default.removeItem(at: folder)
        }
        try #require(await server.waitReady(), "the loopback server")
        let downloads = Downloads(folder: folder)
        let pages = DownloadingPages(downloads)
        let first = downloadPage(pages)
        load("slow", from: server, in: first)
        let started = await eventually { downloads.list.shownItems.first?.name == "race.txt" }
        try #require(started, "the first download: \(downloads.list.shownItems)")
        #expect(downloads.cancel(row: 0))
        let second = downloadPage(pages)
        load("fast", from: server, in: second)
        let done = await eventually { downloads.list.shownItems.first?.state == .finished }
        try #require(done, "the second download: \(downloads.list.shownItems.map(\.stateText))")
        let name = try #require(downloads.list.shownItems.first?.name)
        let path = folder.appendingPathComponent(name).path
        let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? -1
        // P5-FIX-1: the cancelled name stays taken until WebKit confirms; the second may be "race (1).txt".
        #expect(["race.txt", "race (1).txt"].contains(name) && size == 1000, "the second: \(name), \(size) bytes")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        #expect(FileManager.default.fileExists(atPath: path),
                "the finished \(name) was removed by the cancel of the first download")
    }
}
