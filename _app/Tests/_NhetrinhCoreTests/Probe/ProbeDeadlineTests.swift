import Foundation
import Testing
@testable import NhetrinhCore

/// P0-REV-PROBE: `ProbeServer.peerTimeout` says a peer gets 1 s to send its line, but `SO_RCVTIMEO`
/// bounds each `read`, not the line. A peer that sends one byte at a time, each under 1 s apart,
/// holds the server's queue (the app's main queue) for as long as it likes. Expected: the server
/// closes the peer once `peerTimeout` has passed, so the rest of the line cannot be sent and no answer comes back.
@Test(arguments: [0.3, 0.6])
func aPeerThatTricklesItsLineIsDroppedAfterThePeerTimeout(gap: TimeInterval) throws {
    let folder = ProbePath.userTemp() + "nhetrinh-probe-test-" + UUID().uuidString.prefix(8)
    let server = try ProbeServer(folder: folder, queue: DispatchQueue(label: "probe-deadline")) { _ in .done }
    defer { server.stop() }
    let socket = try ProbeSocket.make()
    defer { close(socket) }
    ProbeSocket.setTimeout(socket, 5)
    #expect(try ProbeSocket.withAddress(server.path, { connect(socket, $0, $1) }) == 0)
    let line = Array((try ProbeCodec.encode(ProbeRequest.closeTab) + "\n").utf8)
    let started = Date()
    var sentAll = true
    for byte in line {
        var one = byte
        if write(socket, &one, 1) != 1 { sentAll = false; break }
        Thread.sleep(forTimeInterval: gap)
    }
    let took = Date().timeIntervalSince(started)
    let reply = sentAll ? try? ProbeSocket.readLine(socket) : nil
    #expect(!sentAll, "the server still took bytes \(took) s in; the line would take \(gap * Double(line.count)) s")
    #expect(reply == nil, "the server answered a line that took \(took) s to arrive: \(reply ?? "")")
    #expect(took < ProbeServer.peerTimeout + 2 * gap + 1, "the peer was dropped only after \(took) s")
}
