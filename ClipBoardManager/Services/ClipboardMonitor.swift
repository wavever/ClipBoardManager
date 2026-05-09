import AppKit
import Combine

class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private var onNewContent: ((ClipboardItemType, String, Data?, String?, String) -> Void)?
    
    init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring(interval: TimeInterval = 1.0, onNewContent: @escaping (ClipboardItemType, String, Data?, String?, String) -> Void) {
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
        
        let sourceApp = getActiveAppName()
        
        // Try to read different types
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let isURL = string.hasPrefix("http://") || string.hasPrefix("https://")
            let type: ClipboardItemType = isURL ? .url : .text
            onNewContent?(type, string, nil, nil, sourceApp)
        } else if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
            let content = "[图片 \(imageData.count / 1024)KB]"
            onNewContent?(.image, content, imageData, nil, sourceApp)
        } else if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !fileURLs.isEmpty {
            let paths = fileURLs.map { $0.path }.joined(separator: "\n")
            let firstURL = fileURLs[0]
            let ext = firstURL.pathExtension.lowercased()
            let videoExts = ["mp4", "mov", "avi", "mkv", "webm"]
            let type: ClipboardItemType = videoExts.contains(ext) ? .video : .file
            onNewContent?(type, paths, nil, firstURL.absoluteString, sourceApp)
        } else if let rtfData = pasteboard.data(forType: .rtf) {
            let content = String(data: rtfData, encoding: .utf8) ?? "[富文本]"
            onNewContent?(.rtf, content, nil, nil, sourceApp)
        }
    }
    
    private func getActiveAppName() -> String {
        if let app = NSWorkspace.shared.frontmostApplication {
            return app.localizedName ?? "未知"
        }
        return "未知"
    }
    
    deinit {
        stopMonitoring()
    }
}
