import AppKit
import ImageIO
import NhetrinhCore
import WebKit

/// Site icons (P2): the page's `<link rel="icon">`, else `/favicon.ico` (`FaviconURL`). Each is fetched
/// once, drawn down to 16 pt (32 px, 4 KB) and kept in a memory cache of 200 icons: 800 KB at most.
final class Favicons {
    static let capacity = 200
    static let pixels = 32
    /// An icon wider or taller than this is refused before it is decoded (NT-PRF-003).
    static let largestSide = 2048
    /// The page's icon link, as written in the page (relative or not); null when it has none.
    static let findLink = """
        (() => { const l = [...document.querySelectorAll('link[rel]')]
          .find(e => e.rel.toLowerCase().split(/\\s+/).includes('icon')); return l ? l.getAttribute('href') : null })()
        """
    private static let largest = 512 * 1024

    private var cache = IconCache<URL, NSImage>(capacity: capacity)
    private var missing = IconCache<URL, Bool>(capacity: capacity)
    private var waiting: [URL: [(NSImage?) -> Void]] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.timeoutIntervalForRequest = 10
        return URLSession(configuration: config)
    }()

    /// The icon of the page `webView` shows; `done` runs on the main queue (nil: the site has none).
    func icon(of webView: WKWebView, done: @escaping (NSImage?) -> Void) {
        webView.evaluateJavaScript(Self.findLink) { [weak self, weak webView] href, _ in
            guard let self, let page = webView?.url,
                  let url = FaviconURL.resolve(href: href as? String, page: page) else { return done(nil) }
            self.icon(at: url, done: done)
        }
    }

    func icon(at url: URL, done: @escaping (NSImage?) -> Void) {
        if let image = cache.touch(url) { return done(image) }
        if missing[url] != nil { return done(nil) }
        if waiting[url] != nil {
            waiting[url]?.append(done)
            return
        }
        waiting[url] = [done]
        session.dataTask(with: url) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 200  // a data: URL has no status
            let body = status == 200 ? data.flatMap { $0.count <= Self.largest ? $0 : nil } : nil
            DispatchQueue.main.async { self.finish(url, body) }
        }.resume()
    }

    private func finish(_ url: URL, _ data: Data?) {
        let image = data.flatMap(Self.small)
        if let image { cache[url] = image } else { missing[url] = true }
        waiting.removeValue(forKey: url)?.forEach { $0(image) }
    }

    /// The icon drawn into 32 x 32 pixels, shown at 16 pt: the decoded original is not kept.
    /// Drawing decodes the whole image first, so a small file of huge pixel size is refused (NT-PRF-003).
    static func small(_ data: Data) -> NSImage? {
        guard fits(data), let source = NSImage(data: data), source.isValid,
              let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        source.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.addRepresentation(bitmap)
        return image
    }

    /// Every image in `data` (an .ico holds several) is `largestSide` or less on a side, read from its
    /// header. A bitmap whose size cannot be read is refused; data ImageIO does not know (SVG) is drawn
    /// as a vector by `NSImage`.
    static func fits(_ data: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return true }
        return (0..<CGImageSourceGetCount(source)).allSatisfy { index in
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            guard let width = properties?[kCGImagePropertyPixelWidth] as? Int,
                  let height = properties?[kCGImagePropertyPixelHeight] as? Int else { return false }
            return width <= largestSide && height <= largestSide
        }
    }
}
