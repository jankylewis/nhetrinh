import Foundation
import Testing
@testable import NhetrinhReadback

/// R54 (P11-HISTORY): its two pages carry their own titles; its verdict: the dropdown's first row is the page
/// whose title was typed in part. R54 itself is not run here.
struct HistoryStepTests {
    @Test(arguments: ["/history/alpha", "/history/beta"])
    func eachPageCarriesItsTitle(path: String) throws {
        let title = try #require(ToolPages.historyPages[path])
        let page = String(decoding: try #require(ToolPages.reply(path: path)).body, as: UTF8.self)
        #expect(page.contains("<title>\(title)</title>"))
    }

    @Test func theTypedTextIsPartOfTheFirstPagesTitleOnly() throws {
        let alpha = try #require(ToolPages.historyPages["/history/alpha"])
        let beta = try #require(ToolPages.historyPages["/history/beta"])
        let words = HistoryStep.typed.split(separator: " ").map(String.init)
        #expect(words.allSatisfy(alpha.contains))
        #expect(!words.allSatisfy(beta.contains))
    }

    @Test(arguments: [
        (rows: ["nhetrinh history alpha — http://127.0.0.1:5/history/alpha"], fails: false),
        (rows: ["nhetrinh history alpha — http://127.0.0.1:5/history/alpha — Switch to tab"], fails: false),
        (rows: ["nhetrinh history beta — http://127.0.0.1:5/history/beta",
                "nhetrinh history alpha — http://127.0.0.1:5/history/alpha"], fails: true),
        (rows: ["nhetrinh history alphabet — http://x.test/"], fails: true),
        (rows: [], fails: true),
    ])
    func theVerdict(rows: [String], fails: Bool) {
        #expect((HistoryStep.failure(rows: rows, wanted: "nhetrinh history alpha") != nil) == fails)
    }

    @Test func theStepIsR54() {
        #expect(HistoryStep.step.id == "R54")
    }
}
