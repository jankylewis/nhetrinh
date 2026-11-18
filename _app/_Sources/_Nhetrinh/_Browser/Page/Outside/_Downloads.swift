import AppKit
import NhetrinhCore
import WebKit

/// P5: every download of this launch. The file goes to ~/Downloads under the first free name
/// (`DownloadNamer`); a file there is never replaced. It is written as `<name>.download` and gets its name
/// only when complete, with macOS's quarantine (P5-FIX-1: F1, F5, F6). A cancelled or failed download
/// leaves no file. The name is chosen, and the file first written, off the main thread: macOS holds the
/// first write into ~/Downloads while it asks for access (NT-ENV-004). Rows, stalls, the gate: `+Rows`.
final class Downloads: NSObject, WKDownloadDelegate {
    final class Entry {
        let id: Int
        let download: WKDownload
        /// The page the download came from (its quarantine's origin).
        let page: URL?
        var name: String?
        var file: URL?
        var watch: NSKeyValueObservation?

        init(id: Int, download: WKDownload, page: URL?) {
            self.id = id
            self.download = download
            self.page = page
        }
    }

    var list = DownloadList()
    /// The files Finder was asked to show, by name (the probe's R34).
    var revealed: [String] = []
    var onChange: (() -> Void)?
    var entries: [Entry] = []
    let folder: URL?
    /// Keys (`DownloadNamer.key`) of names given to downloads not ended yet; on `naming` only.
    var reserved: Set<String> = []
    let naming = DispatchQueue(label: "nhetrinh.downloads.naming")
    /// F2: a page's downloads without a click, and the pages asked about now (their waiting downloads).
    var gate = DownloadGate()
    var asking: [String: [(Bool) -> Void]] = [:]
    var stallTimer: Timer?

    init(folder: URL? = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first) {
        self.folder = folder
    }

    func adopt(_ download: WKDownload) {
        download.delegate = self
        let name = DownloadNamer.clean(download.originalRequest?.url?.lastPathComponent ?? "")
        entries.append(Entry(id: list.add(name), download: download, page: download.webView?.url))
        entries.removeAll { list.item($0.id) == nil }  // a row the list dropped
        watchStalls()
        onChange?()
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        guard let entry = entry(download), let folder else { return completionHandler(nil) }
        naming.async { [weak self] in
            let name = self?.reserve(suggestedFilename, in: folder)
            // macOS asks for ~/Downloads here, not on the main thread inside WebKit (NT-ENV-004).
            let writable = name.map { DownloadNamer.canWrite(DownloadNamer.partial($0), in: folder) } ?? false
            DispatchQueue.main.async {
                guard let self else { return completionHandler(nil) }
                guard self.isRunning(entry) else {  // F7: cancelled while its name was chosen
                    self.free(name)
                    return completionHandler(nil)
                }
                guard let name, writable else {
                    self.free(name)
                    let why = name == nil ? "every name is taken in Downloads" : "no access to the Downloads folder"
                    self.end(entry, .failed(why))
                    return completionHandler(nil)
                }
                entry.name = name
                entry.file = folder.appendingPathComponent(DownloadNamer.partial(name))
                self.list.rename(entry.id, name)
                self.watch(entry)
                completionHandler(entry.file)
            }
        }
    }

    /// Complete: quarantined, then renamed from `<name>.download` to its name; the name is then free.
    func downloadDidFinish(_ download: WKDownload) {
        guard let entry = entry(download) else { return }
        guard let partial = entry.file, let name = entry.name else { return end(entry, .failed("no file was made")) }
        let file = partial.deletingLastPathComponent().appendingPathComponent(name)
        do {
            try Quarantine.mark(partial, source: download.originalRequest?.url, page: entry.page)
            try FileManager.default.moveItem(at: partial, to: file)
        } catch {
            Log.web.error("download: could not finish \(name, privacy: .public): \(error.localizedDescription)")
            return end(entry, .failed(Self.reason(error)))
        }
        entry.file = file
        end(entry, .finished)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        guard let entry = entry(download) else { return }
        Log.web.error("download failed: \(error.localizedDescription, privacy: .public)")
        end(entry, .failed(Self.reason(error)))
    }

    /// The footer's Cancel. The name stays taken until WebKit says the download stopped; then its partial
    /// file goes, and only then the name is free (F1: a late removal never hits the next download's file).
    func cancel(row: Int) -> Bool {
        guard let entry = running(row: row) else { return false }
        list.set(entry.id, .cancelled)
        entries.removeAll { $0 === entry }
        entry.watch = nil
        let partial = entry.file
        if let partial { try? FileManager.default.removeItem(at: partial) }
        onChange?()
        entry.download.cancel { [weak self] _ in
            DispatchQueue.main.async {
                if let partial { try? FileManager.default.removeItem(at: partial) }
                self?.free(entry.name)
            }
        }
        return true
    }

    func entry(_ download: WKDownload) -> Entry? { entries.first { $0.download === download } }

    private func isRunning(_ entry: Entry) -> Bool {
        guard entries.contains(where: { $0 === entry }) else { return false }
        if case .running = list.item(entry.id)?.state { return true }
        return false
    }

    /// The download's last state. WebKit has stopped writing (it finished or failed): a partial file goes
    /// at once and the name is free.
    private func end(_ entry: Entry, _ state: DownloadItem.State) {
        guard case .running = list.item(entry.id)?.state else { return }
        list.set(entry.id, state)
        entry.watch = nil
        if state != .finished {
            entries.removeAll { $0 === entry }
            if let file = entry.file { try? FileManager.default.removeItem(at: file) }
        }
        free(entry.name)
        onChange?()
    }
}
