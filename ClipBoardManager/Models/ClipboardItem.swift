import Foundation
import SwiftData
import UniformTypeIdentifiers

enum ClipboardItemType: String, Codable, CaseIterable {
    case text = "text"
    case image = "image"
    case video = "video"
    case file = "file"
    case url = "url"
    case rtf = "rtf"
    
    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .video: return "video"
        case .file: return "folder"
        case .url: return "link"
        case .rtf: return "doc.richtext"
        }
    }
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .image: return "图片"
        case .video: return "视频"
        case .file: return "文件"
        case .url: return "链接"
        case .rtf: return "富文本"
        }
    }
}

@Model
final class ClipboardItem {
    var id: UUID
    var type: String // ClipboardItemType raw value
    var content: String // text content or file path
    var imageData: Data?
    var fileURL: String?
    var sourceApp: String
    var createdAt: Date
    var isFavorite: Bool
    var isPinned: Bool
    var preview: String?
    var embedding: Data?
    var embeddingLang: String?

    init(type: ClipboardItemType, content: String, imageData: Data? = nil, fileURL: String? = nil, sourceApp: String = "", preview: String? = nil) {
        self.id = UUID()
        self.type = type.rawValue
        self.content = content
        self.imageData = imageData
        self.fileURL = fileURL
        self.sourceApp = sourceApp
        self.createdAt = Date()
        self.isFavorite = false
        self.isPinned = false
        self.preview = preview
        self.embedding = nil
        self.embeddingLang = nil
    }
    
    var itemType: ClipboardItemType {
        ClipboardItemType(rawValue: type) ?? .text
    }
    
    var resolvedFileURL: URL? {
        if let raw = fileURL, !raw.isEmpty {
            if raw.hasPrefix("file://"), let url = URL(string: raw) {
                return url
            }
            return URL(fileURLWithPath: raw)
        }
        let firstLine = content.split(separator: "\n").first.map(String.init) ?? content
        guard !firstLine.isEmpty else { return nil }
        if firstLine.hasPrefix("file://"), let url = URL(string: firstLine) {
            return url
        }
        if firstLine.hasPrefix("/") {
            return URL(fileURLWithPath: firstLine)
        }
        return nil
    }

    /// Human-friendly tag shown in the list row, e.g. "音频文件"、"软件包"、"文本".
    /// Falls back to the broad displayName when no file URL is available.
    var descriptiveTag: String {
        switch itemType {
        case .text: return "文本"
        case .url: return "链接"
        case .rtf: return "富文本"
        case .image, .video, .file:
            if let url = resolvedFileURL {
                return Self.descriptiveTag(forFileURL: url)
            }
            switch itemType {
            case .image: return "图片"
            case .video: return "视频"
            default: return "文件"
            }
        }
    }

    private static func descriptiveTag(forFileURL url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        // Bundle/installer extensions where macOS would otherwise just say "目录"
        switch ext {
        case "app": return "应用程序"
        case "pkg", "mpkg": return "安装包"
        case "dmg": return "磁盘映像"
        case "ipa": return "应用包"
        default: break
        }

        // Detect directory before falling back to extension lookup
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if exists, isDir.boolValue {
            return "文件夹"
        }

        guard let type = UTType(filenameExtension: ext) else { return "文件" }

        if type.conforms(to: .audio) { return "音频文件" }
        if type.conforms(to: .movie) { return "视频文件" }
        if type.conforms(to: .image) { return "图片文件" }
        if type.conforms(to: .pdf) { return "PDF 文档" }
        if type.conforms(to: .archive) || type.conforms(to: .zip) { return "压缩文件" }
        if type.conforms(to: .sourceCode) { return "代码文件" }
        if type.conforms(to: .spreadsheet) { return "电子表格" }
        if type.conforms(to: .presentation) { return "演示文稿" }
        if type.conforms(to: .html) { return "网页文件" }
        if type.conforms(to: .json) { return "JSON 文件" }
        if type.conforms(to: .xml) { return "XML 文件" }
        if type.conforms(to: .rtf) { return "富文本文件" }
        if type.conforms(to: .plainText) || type.conforms(to: .text) { return "文本文件" }
        if type.conforms(to: .applicationBundle) { return "应用程序" }
        if type.conforms(to: .application) { return "软件包" }
        if type.conforms(to: .folder) { return "文件夹" }

        return type.localizedDescription ?? "文件"
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: createdAt)
        } else if calendar.isDateInYesterday(createdAt) {
            formatter.dateFormat = "HH:mm"
            return "昨天 " + formatter.string(from: createdAt)
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            return formatter.string(from: createdAt)
        }
    }
}
