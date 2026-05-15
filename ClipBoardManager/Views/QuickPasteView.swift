import SwiftUI
import AppKit

struct QuickPasteView: View {
    let items: [ClipboardItem]
    var onCommit: ([ClipboardItem]) -> Void
    var onCancel: () -> Void

    /// Selection in click order. Used to drive numeric badges and to preserve
    /// concatenation order at commit time.
    @State private var selectedIDs: [UUID] = []
    @State private var hoverID: UUID? = nil

    private var selectedItems: [ClipboardItem] {
        selectedIDs.compactMap { id in items.first(where: { $0.id == id }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            list
            Divider().opacity(0.4)
            footer
        }
        .frame(width: 360, height: 440)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("快速粘贴")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(selectedIDs.isEmpty
                 ? "点击任一条粘贴，或多选后点按钮"
                 : "已选 \(selectedIDs.count) 条")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(items, id: \.id) { item in
                    row(for: item)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    private func row(for item: ClipboardItem) -> some View {
        let order = selectedIDs.firstIndex(of: item.id).map { $0 + 1 }
        let isSelected = order != nil
        let isHover = hoverID == item.id

        return HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.18))
                    .frame(width: 22, height: 22)
                if let order {
                    Text("\(order)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: item.itemType.icon)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(displayPreview(for: item))
                    .font(.system(size: 12.5))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text(item.descriptiveTag)
                    Text("·")
                    if item.sourceApp == "通用剪贴板" {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    Text(item.sourceApp.isEmpty ? "未知来源" : item.sourceApp)
                    Spacer(minLength: 0)
                    Text(item.formattedDate)
                }
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected
                      ? Color.accentColor.opacity(0.12)
                      : (isHover ? Color.secondary.opacity(0.10) : Color.clear))
        )
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onHover { hoverID = $0 ? item.id : nil }
        .onTapGesture(count: 2) {
            // Double-click on a single item: paste it directly without needing
            // the button (mirrors the typical clipboard-popup interaction).
            onCommit([item])
        }
        .onTapGesture {
            toggle(item)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                onCancel()
            } label: {
                Text("取消")
                    .font(.system(size: 12))
                    .frame(minWidth: 56)
            }
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Button {
                onCommit(selectedItems)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "return")
                    Text(selectedIDs.count <= 1
                         ? "粘贴"
                         : "按顺序粘贴 (\(selectedIDs.count))")
                }
                .font(.system(size: 12, weight: .semibold))
                .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIDs.isEmpty)
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func toggle(_ item: ClipboardItem) {
        if let idx = selectedIDs.firstIndex(of: item.id) {
            selectedIDs.remove(at: idx)
        } else {
            selectedIDs.append(item.id)
        }
    }

    private func displayPreview(for item: ClipboardItem) -> String {
        if let p = item.preview, !p.isEmpty { return p }
        if !item.content.isEmpty { return item.content }
        return item.descriptiveTag
    }
}
