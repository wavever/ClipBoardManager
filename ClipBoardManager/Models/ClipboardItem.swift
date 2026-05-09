import Foundation
import SwiftData

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
