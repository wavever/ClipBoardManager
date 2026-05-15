import SwiftUI
import SwiftData
import AppKit

/// Lists soft-deleted clipboard items. Each row offers "恢复" (move back to
/// active history) and "彻底删除" (hard-delete). A header shows how many
/// items are queued and how soon they'll be auto-purged.
struct TrashPanelView: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Query(sort: \ClipboardItem.deletedAt, order: .reverse) private var allItems: [ClipboardItem]
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var nav = AppNavigation.shared
    @ObservedObject private var filters = FilterSettingsStore.shared

    private var trashed: [ClipboardItem] {
        allItems.filter { $0.deletedAt != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 14)

            if trashed.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(trashed) { item in
                            row(for: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.red.opacity(0.07), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: { nav.showList() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("返回")
            .keyboardShortcut(.escape, modifiers: [])

            VStack(alignment: .leading, spacing: 2) {
                Text("垃圾桶")
                    .font(.system(size: 28, weight: .bold))
                Text(captionText)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !trashed.isEmpty {
                Button(role: .destructive) {
                    vm.emptyTrash(context: modelContext)
                    ToastCenter.shared.show("已清空垃圾桶", systemImage: "trash.slash.fill", tint: .red)
                } label: {
                    Label("清空垃圾桶", systemImage: "trash.slash")
                }
            }
        }
    }

    private var captionText: String {
        if trashed.isEmpty { return "已删除的条目会先进入这里" }
        let retention = filters.trashRetentionDays
        if retention <= 0 {
            return "共 \(trashed.count) 条 · 永久保留"
        }
        return "共 \(trashed.count) 条 · \(retention) 天后自动清理"
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "trash")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(Color.secondary.opacity(0.5))
            Text("垃圾桶是空的")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("从历史中删除条目后会出现在这里，过期会自动清理")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func row(for item: ClipboardItem) -> some View {
        HStack(spacing: 12) {
            ThumbnailView(item: item, size: 40, cornerRadius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle(for: item))
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(item.descriptiveTag)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule().fill(.secondary.opacity(0.14))
                        )
                    Text("删除于 " + relativeDeleted(item))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(expiryHint(for: item))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 12)

            Button {
                vm.restoreItem(item, context: modelContext)
                ToastCenter.shared.show("已恢复", systemImage: "arrow.uturn.backward", tint: .accentColor)
            } label: {
                Label("恢复", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                vm.purgeItem(item, context: modelContext)
                ToastCenter.shared.show("已彻底删除", systemImage: "trash.fill", tint: .red)
            } label: {
                Label("彻底删除", systemImage: "trash")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 11)
                .fill(.regularMaterial)
                .opacity(0.55)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(.separator.opacity(0.25), lineWidth: 0.5)
        )
    }

    private func displayTitle(for item: ClipboardItem) -> String {
        if let preview = item.preview, preview.hasPrefix("[合并 ") {
            return preview.components(separatedBy: .newlines).first ?? preview
        }
        if let url = item.resolvedFileURL { return url.lastPathComponent }
        let firstLine = (item.preview ?? item.content)
            .components(separatedBy: .newlines)
            .first ?? ""
        return firstLine.isEmpty ? item.itemType.displayName : firstLine
    }

    private func relativeDeleted(_ item: ClipboardItem) -> String {
        guard let deletedAt = item.deletedAt else { return "" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f.localizedString(for: deletedAt, relativeTo: Date())
    }

    private func expiryHint(for item: ClipboardItem) -> String {
        let days = filters.trashRetentionDays
        guard days > 0, let deletedAt = item.deletedAt else { return "" }
        let remaining = deletedAt.addingTimeInterval(Double(days) * 86_400)
            .timeIntervalSince(Date())
        if remaining <= 0 { return "· 即将清理" }
        let hours = Int(remaining / 3600)
        if hours < 24 { return "· \(hours)h 后清理" }
        return "· \(hours / 24)d 后清理"
    }
}
