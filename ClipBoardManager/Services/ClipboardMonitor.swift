import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    typealias Callback = (ClipboardItemType, String, Data?, String?, String, String) -> Void

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private var onNewContent: Callback?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring(interval: TimeInterval = 1.0, onNewContent: @escaping Callback) {
        self.onNewContent = onNewContent
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        let (sourceApp, bundleId) = getActiveApp()

        // 1. 文件 URL 优先：从 Finder 复制时同时存在 file URL 与 string，先认 file URL。
        let fileOnlyOptions: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: fileOnlyOptions) as? [URL],
           !urls.isEmpty {
            let paths = urls.map { $0.path }.joined(separator: "\n")
            let firstURL = urls[0]
            let ext = firstURL.pathExtension.lowercased()
            let videoExts = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
            let imageExts = ["jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "heic", "heif"]
            let type: ClipboardItemType
            if videoExts.contains(ext) {
                type = .video
            } else if imageExts.contains(ext) {
                type = .image
            } else {
                type = .file
            }
            onNewContent?(type, paths, nil, firstURL.absoluteString, sourceApp, bundleId)
            return
        }

        // 2. 原始图片数据（截图、应用拷贝出来的位图）
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let content = "[图片 \(imageData.count / 1024)KB]"
            onNewContent?(.image, content, imageData, nil, sourceApp, bundleId)
            return
        }

        // 3. 普通字符串
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let isURL = string.hasPrefix("http://") || string.hasPrefix("https://")
            let type: ClipboardItemType = isURL ? .url : .text
            onNewContent?(type, string, nil, nil, sourceApp, bundleId)
            return
        }

        // 4. 富文本
        if let rtfData = pasteboard.data(forType: .rtf) {
            let content = String(data: rtfData, encoding: .utf8) ?? "[富文本]"
            onNewContent?(.rtf, content, nil, nil, sourceApp, bundleId)
            return
        }
    }
    
    private func getActiveApp() -> (name: String, bundleId: String) {
        if let app = NSWorkspace.shared.frontmostApplication {
            return (app.localizedName ?? "未知", app.bundleIdentifier ?? "")
        }
        return ("未知", "")
    }
    
    deinit {
        stopMonitoring()
    }
}
