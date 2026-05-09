import Foundation
import SwiftUI
import SwiftData
import AppKit

@MainActor
class ClipboardViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedType: ClipboardItemType? = nil
    @Published var selectedItem: ClipboardItem? = nil
    @Published var selectedItems: Set<UUID> = []
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
        
        monitor.startMonitoring { [weak self] type, content, imageData, fileURL, sourceApp in
            guard let self = self else { return }
            
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
            }
        case .video, .file:
            if let path = item.fileURL, let url = URL(string: path) {
                pasteboard.writeObjects([url as NSURL])
            }
        }
    }
    
    func deleteItem(_ item: ClipboardItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
        if selectedItem?.id == item.id {
            selectedItem = nil
        }
    }
    
    func deleteItems(_ items: [ClipboardItem], context: ModelContext) {
        for item in items {
            context.delete(item)
        }
        try? context.save()
        selectedItems.removeAll()
    }
    
    func deleteAll(context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>()
        if let all = try? context.fetch(descriptor) {
            for item in all {
                context.delete(item)
            }
            try? context.save()
        }
        selectedItems.removeAll()
        selectedItem = nil
    }
    
    func toggleFavorite(_ item: ClipboardItem) {
        item.isFavorite.toggle()
    }
    
    func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
    }
    
    func toggleSelection(_ id: UUID) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }
    
    func selectAll(_ items: [ClipboardItem]) {
        selectedItems = Set(items.map { $0.id })
    }
    
    func deselectAll() {
        selectedItems.removeAll()
    }
    
    func filteredItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        var result = items
        
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
        
        return result
    }
}
