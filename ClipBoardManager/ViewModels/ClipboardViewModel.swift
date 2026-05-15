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
    @Published var semanticSearchEnabled = false
    @Published var isSelectionMode = false
    @Published var selectedItemIDs: Set<UUID> = []
    @Published var showSnippetEditor = false

    /// Minimum cosine similarity for a clip to show up in semantic results.
    /// Apple's sentence embeddings produce mostly-positive scores for related
    /// text in the 0.3–0.8 range; below ~0.25 is usually noise.
    private let semanticThreshold: Float = 0.25

    let monitor = ClipboardMonitor()
    private var retentionTimer: Timer?
    
    var filteredTypeDisplayName: String {
        selectedType?.displayName ?? "全部"
    }
    
    /// Drop entries that are older than the per-type retention setting and
    /// hard-delete trashed items past their grace period. Pinned and favorited
    /// items are exempt from per-type retention — users marked them on purpose.
    func applyRetentionCleanup(context: ModelContext) {
        let filters = FilterSettingsStore.shared
        let descriptor = FetchDescriptor<ClipboardItem>()
        guard let items = try? context.fetch(descriptor) else { return }
        let now = Date()
        var deleted = 0

        // 1) Purge expired trash.
        let trashDays = filters.trashRetentionDays
        if trashDays > 0 {
            let trashCutoff = now.addingTimeInterval(-Double(trashDays) * 86_400)
            for item in items {
                guard let deletedAt = item.deletedAt else { continue }
                if deletedAt < trashCutoff {
                    context.delete(item)
                    deleted += 1
                }
            }
        }

        // 2) Per-type retention on live history.
        if !filters.retentionByType.isEmpty {
            for item in items where item.deletedAt == nil && !item.isPinned && !item.isFavorite {
                let days = filters.retentionDays(for: item.itemType)
                guard days > 0 else { continue }
                let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
                if item.createdAt < cutoff {
                    if filters.trashEnabled {
                        // Move into trash so user has a chance to recover.
                        item.deletedAt = now
                    } else {
                        context.delete(item)
                        deleted += 1
                    }
                }
            }
        }

        if deleted > 0 { try? context.save() } else { try? context.save() }
    }

    /// All trashed items, newest deletion first.
    func trashedItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.filter { $0.deletedAt != nil }
             .sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    private func scheduleRetentionTimer(context: ModelContext) {
        retentionTimer?.invalidate()
        retentionTimer = Timer.scheduledTimer(withTimeInterval: 3_600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.applyRetentionCleanup(context: context)
            }
        }
    }

    func startMonitoring(context: ModelContext) {
        applyRetentionCleanup(context: context)
        scheduleRetentionTimer(context: context)

        monitor.startMonitoring { [weak self] type, rawContent, imageData, fileURL, sourceApp, bundleId in
            guard self != nil else { return }

            // Drop utm_*/fbclid/etc. before the URL ever lands in history.
            let content: String = {
                guard type == .url, FilterSettingsStore.shared.stripURLTracking else {
                    return rawContent
                }
                return URLSanitizer.clean(rawContent)
            }()

            // Apply user filter rules first.
            if FilterSettingsStore.shared.shouldExclude(
                type: type,
                content: content,
                sourceBundleId: bundleId
            ) {
                return
            }

            // Re-copying the same content shouldn't grow a wall of duplicates
            // — refresh the existing entry's timestamp so it bubbles back to
            // the top, and still count the copy in stats.
            let recentDescriptor = FetchDescriptor<ClipboardItem>(
                predicate: #Predicate { $0.content == content },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            if let existing = try? context.fetch(recentDescriptor),
               let mostRecent = existing.first {
                mostRecent.createdAt = Date()
                try? context.save()
                CopyStatsStore.shared.recordCopy()
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
            try? context.save()

            // Bump today's copy counter (guarded by user's toggle).
            CopyStatsStore.shared.recordCopy()

            // Compute embedding off the main thread, then write back.
            let embedContent = content
            Task { @MainActor in
                let emb = await EmbeddingService.shared.embedAsync(embedContent)
                guard let emb else { return }
                item.embedding = emb.data
                item.embeddingLang = emb.language
                try? context.save()
            }
            
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
        retentionTimer?.invalidate()
        retentionTimer = nil
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.itemType {
        case .text, .rtf, .url:
            // Optional cleanup: drop trailing whitespace/newlines that almost
            // never matter but commonly leak in from triple-click or
            // select-all in editors.
            var output = item.content
            if UserDefaults.standard.bool(forKey: "trimTrailingWhitespaceOnCopy") {
                output = output.replacingOccurrences(
                    of: "\\s+$",
                    with: "",
                    options: .regularExpression
                )
            }
            pasteboard.setString(output, forType: .string)
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
    
    /// Hand-authored entry created via the snippet editor. Lives alongside
    /// captured clips but tagged with sourceApp="片段" so it's distinguishable.
    @discardableResult
    func createSnippet(
        content: String,
        type: ClipboardItemType,
        pinned: Bool,
        context: ModelContext
    ) -> ClipboardItem {
        let item = ClipboardItem(
            type: type,
            content: content,
            sourceApp: "片段",
            preview: String(content.prefix(200))
        )
        item.isPinned = pinned
        context.insert(item)
        try? context.save()

        // Embed off-thread so the snippet shows up in semantic search.
        Task { @MainActor in
            let emb = await EmbeddingService.shared.embedAsync(content)
            guard let emb else { return }
            item.embedding = emb.data
            item.embeddingLang = emb.language
            try? context.save()
        }
        return item
    }

    func deleteItem(_ item: ClipboardItem, context: ModelContext) {
        if FilterSettingsStore.shared.trashEnabled {
            // Soft-delete: keep the row around until trash retention expires.
            item.deletedAt = Date()
            try? context.save()
        } else {
            context.delete(item)
            try? context.save()
        }
    }

    /// Move an item back out of the trash. No-op for items that aren't trashed.
    func restoreItem(_ item: ClipboardItem, context: ModelContext) {
        guard item.deletedAt != nil else { return }
        item.deletedAt = nil
        item.createdAt = Date()
        try? context.save()
    }

    /// Hard-delete a single trashed item.
    func purgeItem(_ item: ClipboardItem, context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    /// Drop every trashed entry. The active history is untouched.
    func emptyTrash(context: ModelContext) {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { $0.deletedAt != nil }
        )
        if let trashed = try? context.fetch(descriptor) {
            for item in trashed { context.delete(item) }
            try? context.save()
        }
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

    // MARK: - Selection / Merge

    func enterSelectionMode() {
        isSelectionMode = true
        selectedItemIDs.removeAll()
    }

    func exitSelectionMode() {
        isSelectionMode = false
        selectedItemIDs.removeAll()
    }

    func toggleSelection(_ item: ClipboardItem) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    func isSelected(_ item: ClipboardItem) -> Bool {
        selectedItemIDs.contains(item.id)
    }

    /// Items currently selected, in chronological order (oldest first).
    func orderedSelectedItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.filter { selectedItemIDs.contains($0.id) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Merging requires ≥2 entries of the same type. Images are allowed only
    /// when the user has explicitly enabled image stitching in settings.
    func canMerge(selectedItems: [ClipboardItem]) -> Bool {
        mergeBlockReason(selectedItems: selectedItems) == nil
    }

    /// Inspect the selection and report why merge is blocked (or nil if it's OK).
    func mergeBlockReason(selectedItems: [ClipboardItem]) -> String? {
        if selectedItems.count < 2 { return "至少选择两条" }
        let types = Set(selectedItems.map { $0.itemType })
        if types.count > 1 { return "仅支持同类型合并" }
        if types.first == .image, !MergeSettingsStore.shared.enableImageMerge {
            return "图片合并未启用（设置 → 合并）"
        }
        return nil
    }

    /// Concatenate (or stitch, for images) the selected items into a new
    /// ClipboardItem using user-configured separators / direction. Original
    /// entries are deleted when the "delete originals" preference is on.
    @discardableResult
    func mergeSelected(_ selectedItems: [ClipboardItem], context: ModelContext) -> ClipboardItem? {
        guard canMerge(selectedItems: selectedItems) else { return nil }
        let sorted = selectedItems.sorted { $0.createdAt < $1.createdAt }
        guard let type = sorted.first?.itemType else { return nil }

        let settings = MergeSettingsStore.shared
        let sourceApps = Array(NSOrderedSet(array: sorted.map { $0.sourceApp }.filter { !$0.isEmpty }))
            as? [String] ?? []
        let sourceApp = sourceApps.count == 1 ? sourceApps[0] : "合并 (\(sorted.count) 条)"

        let merged: ClipboardItem
        switch type {
        case .text, .rtf, .url:
            let sep = settings.resolvedTextSeparator()
            let mergedContent = sorted.map { $0.content }.joined(separator: sep)
            // Build a one-line summary so the row title clearly reads as a
            // merged entry instead of looking identical to the first source
            // item (which is what naive `prefix(200)` produces).
            let inline = sorted
                .map { $0.content.replacingOccurrences(of: "\n", with: " ") }
                .joined(separator: " · ")
            let preview = "[合并 \(sorted.count) 条] " + String(inline.prefix(180))
            merged = ClipboardItem(
                type: type,
                content: mergedContent,
                sourceApp: sourceApp,
                preview: preview
            )
        case .file, .video:
            let sep = settings.resolvedFileSeparator()
            let mergedContent = sorted.map { $0.content }.joined(separator: sep)
            let names = sorted
                .map { $0.resolvedFileURL?.lastPathComponent ?? $0.content }
                .joined(separator: " · ")
            let preview = "[合并 \(sorted.count) 项] " + String(names.prefix(180))
            merged = ClipboardItem(
                type: type,
                content: mergedContent,
                sourceApp: sourceApp,
                preview: preview
            )
        case .image:
            let images = sorted.compactMap { ImageStitcher.imageFromItem($0) }
            guard images.count == sorted.count,
                  let stitched = ImageStitcher.stitch(
                    images,
                    direction: settings.imageDirection,
                    spacing: CGFloat(settings.imageSpacing),
                    background: settings.imageBackground.nsColor
                  )
            else { return nil }
            let content = "[图片 拼接 \(sorted.count) 张 · \(stitched.count / 1024)KB]"
            merged = ClipboardItem(
                type: .image,
                content: content,
                imageData: stitched,
                sourceApp: sourceApp,
                preview: content
            )
        }

        context.insert(merged)

        if settings.deleteOriginals {
            for item in sorted { context.delete(item) }
        }
        try? context.save()

        // Compute embedding asynchronously for text-like merges.
        if type != .image {
            let embedContent = merged.content
            Task { @MainActor in
                let emb = await EmbeddingService.shared.embedAsync(embedContent)
                guard let emb else { return }
                merged.embedding = emb.data
                merged.embeddingLang = emb.language
                try? context.save()
            }
        }

        exitSelectionMode()
        return merged
    }

    // MARK: - Bulk selection helpers

    func selectAll(_ items: [ClipboardItem]) {
        selectedItemIDs = Set(items.map(\.id))
    }

    func invertSelection(_ items: [ClipboardItem]) {
        let allIDs = Set(items.map(\.id))
        selectedItemIDs = allIDs.subtracting(selectedItemIDs)
    }

    func clearSelection() {
        selectedItemIDs.removeAll()
    }

    // MARK: - Embedding backfill

    /// One-shot pass: compute embeddings for any historical items that are
    /// missing one. Runs on a detached task to avoid blocking the UI.
    func backfillEmbeddings(context: ModelContext) {
        Task { @MainActor in
            // Re-embed items missing a vector OR whose vector was computed
            // with a different model (dimension mismatch).
            let descriptor = FetchDescriptor<ClipboardItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            guard let orphans = try? context.fetch(descriptor) else { return }
            for item in orphans {
                guard !Task.isCancelled else { break }
                guard item.itemType != .image else { continue }
                // Skip items that already have a correctly-sized vector.
                if let existing = item.embedding, existing.count == 2048 { continue }
                let text = item.content
                let vec = await EmbeddingService.shared.embedAsync(text)
                guard let vec else { continue }
                item.embedding = vec.data
                item.embeddingLang = vec.language
            }
            try? context.save()
        }
    }

    // MARK: - Filtering

    func filteredItems(_ items: [ClipboardItem]) -> [ClipboardItem] {
        // Active history never shows soft-deleted entries — those live in
        // the trash screen until they're restored or expire.
        var result = items.filter { $0.deletedAt == nil }

        switch selectedScope {
        case .all: break
        case .favorites: result = result.filter { $0.isFavorite }
        case .pinned: result = result.filter { $0.isPinned }
        }

        if let type = selectedType {
            result = result.filter { $0.itemType == type }
        }

        // When merging, the user can only combine items of one type. Once a
        // first item is selected we lock the visible list to that same type so
        // incompatible rows can't be tapped by mistake.
        if isSelectionMode,
           let anchorType = items.first(where: { selectedItemIDs.contains($0.id) })?.itemType {
            result = result.filter { $0.itemType == anchorType }
        }

        if !searchText.isEmpty {
            if semanticSearchEnabled {
                result = semanticFilter(result, query: searchText)
            } else {
                let query = searchText.lowercased()
                result = result.filter {
                    $0.content.lowercased().contains(query) ||
                    $0.sourceApp.lowercased().contains(query)
                }
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

    /// Rank items by cosine similarity to the query embedding.
    /// Since all items use the same underlying model (English sentence
    /// embedding), we compare every item regardless of the stored language
    /// tag. Falls back to keyword match when the query can't be embedded.
    private func semanticFilter(_ items: [ClipboardItem], query: String) -> [ClipboardItem] {
        let service = EmbeddingService.shared
        guard let queryVec = service.embed(query) else {
            let q = query.lowercased()
            return items.filter {
                $0.content.lowercased().contains(q) ||
                $0.sourceApp.lowercased().contains(q)
            }
        }

        struct Scored { let item: ClipboardItem; let score: Float }

        var scored: [Scored] = []
        for item in items {
            guard let vecData = item.embedding, vecData.count == queryVec.data.count else { continue }
            let sim = service.cosineSimilarity(queryVec.data, vecData)
            if sim >= semanticThreshold {
                scored.append(Scored(item: item, score: sim))
            }
        }
        scored.sort { $0.score > $1.score }
        // Fall back to keyword search if semantic matching found nothing.
        if scored.isEmpty {
            let q = query.lowercased()
            return items.filter {
                $0.content.lowercased().contains(q) ||
                $0.sourceApp.lowercased().contains(q)
            }
        }
        return scored.map { $0.item }
    }
}
