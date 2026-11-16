import Foundation
import Testing
@testable import NhetrinhCore

@Test(arguments: [
    ("https://example.com/a?b=1", "https://example.com/a?b=1"),
    ("example.com", "https://example.com"),
    ("  github.com/jankylewis  ", "https://github.com/jankylewis"),
    ("localhost:8080", "https://localhost:8080"),
    ("file:///tmp/x.html", "file:///tmp/x.html"),
])
func urlsStayUrls(input: String, expected: String) {
    #expect(AddressParser.url(from: input)?.absoluteString == expected)
}

@Test(arguments: [
    ("hello world", "hello%20world"),
    ("swift", "swift"),
    ("rock & roll", "rock%20%26%20roll"),
    ("c++ = fast?", "c%2B%2B%20%3D%20fast%3F"),
    ("issue #12", "issue%20%2312"),
])
func textBecomesOneSearchQuery(input: String, encoded: String) {
    #expect(AddressParser.url(from: input)?.absoluteString == AddressParser.searchTemplate + encoded)
}

@Test(arguments: ["", "   ", "\n"])
func blankInputIsNoUrl(input: String) {
    #expect(AddressParser.url(from: input) == nil)
}
