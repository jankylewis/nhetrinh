import Foundation
import Testing
@testable import NhetrinhCore

/// A real Unix socket in a folder of its own under the user's temporary folder; no app involved.
private func withServer(_ body: (String, ProbeServer) throws -> Void) throws {
    let folder = ProbePath.userTemp() + "nhetrinh-probe-test-" + UUID().uuidString.prefix(8)
    let queue = DispatchQueue(label: "probe-test")
    let server = try ProbeServer(folder: folder, queue: queue) { request in
        switch request {
        case .state:
            var state = ProbeState()
            state.rows = ["one", "two"]
            state.selected = 1
            return .state(state)
        case .select(let index) where index > 1: return .failed("no row \(index)")
        default: return .done
        }
    }
    defer { server.stop() }
    try body(folder, server)
}

@Test func stateRequestIsAnsweredOverTheSocket() throws {
    try withServer { (_: String, server: ProbeServer) throws in
        let response = try ProbeClient.send(.state, to: server.path)
        guard case .state(let state) = response else { throw ProbeError.unexpected("\(response)") }
        #expect(state.rows == ["one", "two"] && state.selected == 1)
    }
}

@Test(arguments: [(ProbeRequest.newTab, ProbeResponse.done), (.select(5), .failed("no row 5")), (.select(0), .done)])
func actionsAreAnsweredInOrder(request: ProbeRequest, response: ProbeResponse) throws {
    try withServer { (_: String, server: ProbeServer) throws in
        for _ in 0..<3 { #expect(try ProbeClient.send(request, to: server.path) == response) }
    }
}

@Test func malformedLineIsAnsweredFailedAndTheServerStaysUp() throws {
    try withServer { (_: String, server: ProbeServer) throws in
        let reply = try ProbeClient.exchange("{\"op\":\"format-disk\"}", with: server.path)
        #expect(try ProbeCodec.decodeResponse(reply) == .failed("malformed request"))
        #expect(try ProbeClient.send(.closeTab, to: server.path) == .done)
    }
}

@Test func onlyTheOwnerCanReachTheSocket() throws {
    try withServer { (folder: String, server: ProbeServer) throws in
        let manager = FileManager.default
        let folderMode = try manager.attributesOfItem(atPath: folder)[.posixPermissions] as? Int
        let socketMode = try manager.attributesOfItem(atPath: server.path)[.posixPermissions] as? Int
        #expect(folderMode == 0o700)
        #expect(socketMode == 0o600)
    }
}

@Test func stopRemovesTheFolder() throws {
    var folder = ""
    try withServer { (inner: String, server: ProbeServer) throws in
        folder = inner
        server.stop()
    }
    #expect(!FileManager.default.fileExists(atPath: folder))
}

@Test func noServerIsAnErrorNotAHang() {
    let path = ProbePath.userTemp() + "nhetrinh-probe-none-" + UUID().uuidString.prefix(8) + "/probe.sock"
    #expect(throws: ProbeError.self) { try ProbeClient.send(.state, to: path, timeout: 1) }
}
