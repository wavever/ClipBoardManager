import AppKit
import UniformTypeIdentifiers

class ExportService {
    static let shared = ExportService()
    
    func exportItem(_ item: ClipboardItem, to directory: URL? = nil) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        
        switch item.itemType {
        case .text, .rtf, .url:
            savePanel.allowedContentTypes = [.plainText]
            savePanel.nameFieldStringValue = "clipboard_\(item.id.uuidString.prefix(8)).txt"
        case .image:
            savePanel.allowedContentTypes = [.png]
            savePanel.nameFieldStringValue = "clipboard_\(item.id.uuidString.prefix(8)).png"
        case .video:
            savePanel.allowedContentTypes = [.movie]
            savePanel.nameFieldStringValue = "clipboard_\(item.id.uuidString.prefix(8)).mp4"
        case .file:
            savePanel.allowedContentTypes = [.data]
            savePanel.nameFieldStringValue = "clipboard_\(item.id.uuidString.prefix(8))"
        }
        
        guard let directory = directory else {
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    self.writeItem(item, to: url)
                }
            }
            return nil
        }
        
        let filename = savePanel.nameFieldStringValue
        let url = directory.appendingPathComponent(filename)
        return writeItem(item, to: url) ? url : nil
    }
    
    func exportBatch(_ items: [ClipboardItem]) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "选择导出目录"
        
        panel.begin { response in
            guard response == .OK, let directory = panel.url else { return }
            for item in items {
                _ = self.exportItem(item, to: directory)
            }
        }
    }
    
    @discardableResult
    private func writeItem(_ item: ClipboardItem, to url: URL) -> Bool {
        do {
            switch item.itemType {
            case .text, .rtf, .url:
                try item.content.write(to: url, atomically: true, encoding: .utf8)
            case .image:
                if let data = item.imageData {
                    try data.write(to: url)
                } else {
                    return false
                }
            case .video, .file:
                if let path = item.fileURL, let sourceURL = URL(string: path) {
                    let fileManager = FileManager.default
                    if fileManager.fileExists(atPath: url.path) {
                        try fileManager.removeItem(at: url)
                    }
                    try fileManager.copyItem(at: sourceURL, to: url)
                } else {
                    try item.content.write(to: url, atomically: true, encoding: .utf8)
                }
            }
            return true
        } catch {
            print("Export failed: \(error)")
            return false
        }
    }
}
