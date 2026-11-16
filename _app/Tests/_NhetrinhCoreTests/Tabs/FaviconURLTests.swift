import Foundation
import Testing
@testable import NhetrinhCore

// P2 tests (hubs/product/plan/M1_DAILY_DRIVER.md), red first (P2-PREP-1):
// `FaviconURL.resolve` is a stub, so every case here fails until P2 builds it.

private func url(_ text: String) -> URL {
    URL(string: text) ?? URL(fileURLWithPath: "/not-a-url")
}

private let page = "https://example.com/docs/guide.html?x=1#top"

@Test(arguments: [
    ("/static/icon.png", page, "https://example.com/static/icon.png"),
    ("icon.png", page, "https://example.com/docs/icon.png"),
    ("../img/icon.svg", page, "https://example.com/img/icon.svg"),
    ("//cdn.example.net/i.ico", page, "https://cdn.example.net/i.ico"),
    ("/i.png", "http://localhost:8080/a/b", "http://localhost:8080/i.png"),
])
func relativeHrefResolvesAgainstThePage(href: String, page: String, expected: String) {
    #expect(FaviconURL.resolve(href: href, page: url(page)) == url(expected))
}

@Test(arguments: ["https://cdn.example.net/x.png", "http://example.org/favicon.ico"])
func absoluteHrefIsKept(href: String) {
    #expect(FaviconURL.resolve(href: href, page: url(page)) == url(href))
}

@Test(arguments: [
    (nil, page, "https://example.com/favicon.ico"),
    ("", page, "https://example.com/favicon.ico"),
    ("   ", page, "https://example.com/favicon.ico"),
    ("javascript:alert(1)", page, "https://example.com/favicon.ico"),
    (nil, "http://localhost:8080/a/b?q=1", "http://localhost:8080/favicon.ico"),
] as [(String?, String, String)])
func missingHrefGivesFaviconIcoOfTheOrigin(href: String?, page: String, expected: String) {
    #expect(FaviconURL.resolve(href: href, page: url(page)) == url(expected))
}

@Test(arguments: ["data:image/png;base64,iVBORw0KGgo=", "data:image/svg+xml,%3Csvg%2F%3E"])
func dataHrefIsTheIconItself(href: String) {
    #expect(FaviconURL.resolve(href: href, page: url(page)) == url(href))
}

@Test(arguments: [
    (nil, "file:///tmp/page.html"),
    ("/icon.png", "file:///tmp/page.html"),
    (nil, "about:blank"),
    ("icon.png", "data:text/html,hello"),
] as [(String?, String)])
func nonHttpPageHasNoIcon(href: String?, page: String) {
    #expect(FaviconURL.resolve(href: href, page: url(page)) == nil)
}
