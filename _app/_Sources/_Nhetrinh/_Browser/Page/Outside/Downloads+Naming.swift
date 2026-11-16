import Foundation
import NhetrinhCore

/// A download's name (P5, P5-FIX-1): reserved from the choice until WebKit has stopped writing (F1), the
/// same file in any spelling (F8), never the name of a file or of a partial file already there.
extension Downloads {
    /// The first free name, taken: not reserved (case and normalization ignored, F8), no file of it or of
    /// its partial file in the folder. On `naming`.
    func reserve(_ suggested: String, in folder: URL) -> String? {
        let name = DownloadNamer.freeName(suggested) { name in
            reserved.contains(DownloadNamer.key(name))
                || FileManager.default.fileExists(atPath: folder.appendingPathComponent(name).path)
                || FileManager.default.fileExists(
                    atPath: folder.appendingPathComponent(DownloadNamer.partial(name)).path)
        }
        if let name { reserved.insert(DownloadNamer.key(name)) }
        return name
    }

    func free(_ name: String?) {
        guard let name else { return }
        naming.async { [weak self] in self?.reserved.remove(DownloadNamer.key(name)) }
    }

    /// The reason a failed row shows; no access to ~/Downloads is named as such.
    static func reason(_ error: Error) -> String {
        let error = error as NSError
        let denied = (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError)
            || (error.domain == NSPOSIXErrorDomain && [Int(EPERM), Int(EACCES)].contains(error.code))
        return denied ? "no access to the Downloads folder" : error.localizedDescription
    }
}
