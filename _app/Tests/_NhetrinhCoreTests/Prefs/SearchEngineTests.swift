import Foundation
import Testing
@testable import NhetrinhCore

// P4: the search engine of the Settings Hub, used by the address bar (`AddressParser`).

@Test(arguments: [
    (SearchEngine.google, "https://www.google.com/search?q=rock%20%26%20roll"),
    (.duckDuckGo, "https://duckduckgo.com/?q=rock%20%26%20roll"),
    (.bing, "https://www.bing.com/search?q=rock%20%26%20roll"),
])
func wordsGoToTheChosenEngine(engine: SearchEngine, url: String) {
    #expect(AddressParser.url(from: "rock & roll", engine: engine)?.absoluteString == url)
}

/// An address stays an address whatever the engine.
@Test(arguments: SearchEngine.allCases)
func addressesIgnoreTheEngine(engine: SearchEngine) {
    #expect(AddressParser.url(from: "example.com", engine: engine)?.absoluteString == "https://example.com")
}

@Test func engineChoices() {
    #expect(SearchEngine.allCases.map(\.title) == ["Google", "DuckDuckGo", "Bing"])
    #expect(SearchEngine.allCases.map(\.rawValue) == ["google", "duckduckgo", "bing"])
}
