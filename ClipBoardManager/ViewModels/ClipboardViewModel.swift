import Foundation
import SwiftUI
import SwiftData
import AppKit

enum ListScope: String, CaseIterable, Identifiable {
    case all
    case favorites
    case pinned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return "全部"
        case .favorites: return "收藏"
        case .pinned: return "置顶"
        }
    }

    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .favorites: return "star.fill"
        case .pinned: return "pin.fill"
        }
    }
}

@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedType: ClipboardItemType? = nil
    @Published var selectedScope: ListScope = .all
    @Published var isMonitoring = true
    @Published var showExportPanel = false
    
    let monitor = ClipboardMonitor()
    
    var filteredTypeDisplayName: String {
        selectedType?.displayName ?? "全部"
    }
    
    func startMonitoring(context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        monitor.startMonitoring { [weak self] type, content, imageData, fileURL, sourceApp, bundleId in
            guard let self = self else { return }

            // Apply user filter rules first.
            if FilterSettingsStore.shared.shouldExclude(
                type: type,
                content: content,
                sourceBundleId: bundleId
            ) {
                return
            }

            // Check for duplicate content
            let recentDescriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { $0.content == content },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            if let existing = try? context.fetch(recentDescriptor), !existing.isEmpty {
                return
            }
            
            let item = ClipboardItem(
                type: type,
                content: content,
                imageData: imageData,
                fileURL: fileURL,
                sourceApp: sourceApp,
                preview: String(content.prefix(200))
            )
            context.insert(item)
            
            // Trim old items (keep max 500)
            let countDescriptor = FetchDescriptor<ClipboardItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            if let allItems = try? context.fetch(countDescriptor), allItems.count > 500 {
                for oldItem in allItems.suffix(from: 500) {
                    context.delete(oldItem)
                }
            }
            
            try? context.save()
        }
    }
    
    func stopMonitoring() {
        monitor.stopMonitoring()
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.itemType {
        case .text, .rtf, .url:
            pasteboard.setString(item.content, forType: .string)
        case .image:
            if let data = item.imageData {
                pasteboard.setData(data, forType: .tiff)
            } else if let url = item.resolvedFileURL {
                pasteboard.writeObjects([url as NSURL])
            }
        case .video, .file:
            if let url = item.resolvedFileURL {
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }
    
    func deleteItem(_ item: ClipboardItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }
    
    func deleteAll(context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>()
        if let all = try? context.fetch(descriptor) {
            for item in all {
                context.delete(item)
            }
            try? context.save()
        }
    }

    func toggleFavorite(_ item: ClipboardItem) {
        item.isFavorite.toggle()
    }

    func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
    }

    func filteredItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        var result = items

        switch selectedScope {
        case .all: break
        case .favorites: result = result.filter { $0.isFavorite }
        case .pinned: result = result.filter { $0.isPinned }
        }

        if let type = selectedType {
            result = result.filter { $0.itemType == type }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.content.lowercased().contains(query) ||
                $0.sourceApp.lowercased().contains(query)
            }
        }

        // Pinned items float to the top while preserving the createdAt-desc
        // order from the @Query inside each group.
        if selectedScope != .pinned {
            let pinned = result.filter { $0.isPinned }
            let others = result.filter { !$0.isPinned }
            result = pinned + others
        }

        return result
    }
}
