import Foundation

/// The P5 pages (hubs/product/plan/M2_REAL_SITES_WORK.md, R31-R35). Their names start with
/// `nhetrinh-readback-`: the readback removes only these names from ~/Downloads.
///   /download/attachment  1 MB of text sent as `Content-Disposition: attachment` (R31, R32, R34)
///   /download/slow        20 MB, an attachment, 64 KB every 0.1 s: about 32 s (R33)
enum DownloadPages {
    static let attachmentName = "nhetrinh-readback-attachment.txt"
    static let slowName = "nhetrinh-readback-slow.zip"
    static let attachmentSize = 1_048_576
    static let slowSize = 20 * 1_048_576

    /// The name the `clash`-th copy gets (0: the name itself), as the app names it.
    static func copy(_ name: String, clash: Int) -> String {
        guard clash > 0 else { return name }
        let ext = (name as NSString).pathExtension
        let base = (name as NSString).deletingPathExtension
        return "\(base) (\(clash))" + (ext.isEmpty ? "" : ".\(ext)")
    }

    static func reply(path: String) -> TestPageContent.Reply? {
        switch path {
        case "/download/attachment":
            let line = Data("nhetrinh readback attachment, 1 MB of text\n".utf8)
            var body = Data(capacity: attachmentSize)
            while body.count < attachmentSize { body.append(line) }
            return TestPageContent.Reply(type: "text/plain; charset=utf-8",
                                         headers: ["Content-Disposition: attachment; filename=\"\(attachmentName)\""],
                                         body: Data(body.prefix(attachmentSize)))
        case "/download/slow":
            return TestPageContent.Reply(type: "application/zip",
                                         headers: ["Content-Disposition: attachment; filename=\"\(slowName)\""],
                                         body: Data(count: slowSize), pace: 0.1)
        default: return nil
        }
    }
}
