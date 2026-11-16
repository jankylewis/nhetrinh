import AppKit
import NhetrinhCore
import WebKit

/// P5: every download of this launch. The file goes to ~/Downloads under the first free name
/// (`DownloadNamer`); a file there is never replaced. A cancelled or failed download leaves no file.
/// The name is chosen, and the file first written, off the main thread: macOS holds the first write into
/// ~/Downloads while it asks for access (Info.plist: NSDownloadsFolderUsageDescription); inside WebKit that
/// wait was on the main thread and froze the app (P5-BUILD-1 readback).
final class Downloads: NSObject, WKDownloadDelegate {
    private final class Entry {
        let id: Int
        let download: WKDownload
        var file: URL?
        var watch: NSKeyValueObservation?

        init(id: Int, download: WKDownload) {
            self.id = id
            self.download = download
        }
    }

    private(set) var list = DownloadList()
    /// The files Finder was asked to show, by name (the probe's R34).
    private(set) var revealed: [String] = []
    var onChange: (() -> Void)?
    private var entries: [Entry] = []
    private let folder: URL?
    /// Names given to downloads still running; read and written on `naming` only.
    private var reserved: Set<String> = []
    private let naming = DispatchQueue(label: "nhetrinh.downloads.naming")

    init(folder: URL? = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first) {
        self.folder = folder
    }

    func adopt(_ download: WKDownload) {
        download.delegate = self
        let name = DownloadNamer.clean(download.originalRequest?.url?.lastPathComponent ?? "")
        entries.append(Entry(id: list.add(name), download: download))
        entries.removeAll { list.item($0.id) == nil }  // a row the list dropped
        onChange?()
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        guard let entry = entry(download), let folder else { return completionHandler(nil) }
        naming.async { [weak self] in
            let name = DownloadNamer.freeName(suggestedFilename) { name in
                self?.reserved.contains(name) == true
                    || FileManager.default.fileExists(atPath: folder.appendingPathComponent(name).path)
            }
            if let name { self?.reserved.insert(name) }
            // macOS asks for ~/Downloads here, not on the main thread inside WebKit (P5-BUILD-1 readback).
            let writable = name.map { DownloadNamer.canWrite($0, in: folder) } ?? false
            DispatchQueue.main.async {
                guard let self, let name, writable else {
                    let why = name == nil ? "every name is taken in Downloads" : "no access to the Downloads folder"
                    self?.end(entry, .failed(why))
                    return completionHandler(nil)
                }
                entry.file = folder.appendingPathComponent(name)
                self.list.rename(entry.id, name)
                self.watch(entry)
                completionHandler(entry.file)
            }
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        if let entry = entry(download) { end(entry, .finished) }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        guard let entry = entry(download) else { return }
        Log.web.error("download failed: \(error.localizedDescription, privacy: .public)")
        end(entry, .failed(Self.reason(error)))
    }

    /// The footer's Cancel: the download stops and its partial file is removed.
    func cancel(row: Int) -> Bool {
        guard let entry = running(row: row) else { return false }
        end(entry, .cancelled)
        entry.download.cancel { _ in }
        return true
    }

    /// A click on a finished row: Finder shows the file.
    func reveal(row: Int) -> Bool {
        guard let item = shown(row), item.state == .finished,
              let file = entries.first(where: { $0.id == item.id })?.file,
              NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "") else { return false }
        revealed.append(file.lastPathComponent)
        return true
    }

    func shown(_ row: Int) -> DownloadItem? {
        list.shownItems.indices.contains(row) ? list.shownItems[row] : nil
    }

    private func running(row: Int) -> Entry? {
        guard let item = shown(row), case .running = item.state else { return nil }
        return entries.first { $0.id == item.id }
    }

    private func entry(_ download: WKDownload) -> Entry? { entries.first { $0.download === download } }

    /// Progress in whole percents: the footer redraws at most 100 times a download.
    private func watch(_ entry: Entry) {
        entry.watch = entry.download.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            let done = progress.totalUnitCount > 0 ? progress.fractionCompleted : nil
            DispatchQueue.main.async {
                guard let self, case .running(let shown) = self.list.item(entry.id)?.state else { return }
                if shown.map({ Int($0 * 100) }) == done.map({ Int($0 * 100) }) { return }
                self.list.set(entry.id, .running(done))
                self.onChange?()
            }
        }
    }

    /// The download's last state; a file that did not finish is removed, its name freed.
    private func end(_ entry: Entry, _ state: DownloadItem.State) {
        guard case .running = list.item(entry.id)?.state else { return }  // a cancel is not then a failure
        list.set(entry.id, state)
        entry.watch = nil
        if state != .finished { entries.removeAll { $0 === entry } }
        if let file = entry.file {
            if state != .finished { Self.remove(file, after: 0.5) }
            naming.async { [weak self] in self?.reserved.remove(file.lastPathComponent) }
        }
        onChange?()
    }

    /// WebKit may still write for a moment after a cancel: removed now and once more a little later.
    private static func remove(_ file: URL, after delay: TimeInterval) {
        try? FileManager.default.removeItem(at: file)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { try? FileManager.default.removeItem(at: file) }
    }

    /// The reason a failed row shows; no access to ~/Downloads is named as such.
    static func reason(_ error: Error) -> String {
        let error = error as NSError
        let denied = (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError)
            || (error.domain == NSPOSIXErrorDomain && [Int(EPERM), Int(EACCES)].contains(error.code))
        return denied ? "no access to the Downloads folder" : error.localizedDescription
    }
}
