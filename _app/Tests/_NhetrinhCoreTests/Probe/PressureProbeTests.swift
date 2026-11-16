import Foundation
import Testing
@testable import NhetrinhCore

// P6: the readback-only "simulate pressure" request (NHT_READBACK=1 only; never real system pressure).

@Test(arguments: [UnloadPolicy.Pressure.normal, .warning, .critical])
func pressureRequestRoundTrips(level: UnloadPolicy.Pressure) throws {
    let line = try ProbeCodec.encode(ProbeRequest.pressure(level))
    #expect(try ProbeCodec.decodeRequest(line) == .pressure(level))
    #expect(line.contains("\"op\":\"pressure\"") && line.contains("\"text\":\"\(level.rawValue)\""))
}

/// An unknown or missing level is malformed: the app never guesses a level.
@Test(arguments: [#"{"op":"pressure","text":"severe"}"#, #"{"op":"pressure"}"#, #"{"op":"pressure","text":""}"#])
func aPressureRequestWithoutAKnownLevelIsMalformed(line: String) {
    #expect(throws: ProbeCodec.Failure.self) { try ProbeCodec.decodeRequest(line) }
}
