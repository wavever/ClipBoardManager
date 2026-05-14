import SwiftUI
import AppKit

struct ClipboardItemRow: View {
    let item: ClipboardItem
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onCopy: () -> Void = {}
    var onDelete: () -> Void = {}
    var onToggleFavorite: () -> Void = {}
    var onTogglePin: () -> Void = {}
    var onRevealInFinder: () -> Void = {}
    var onOpenFile: () -> Void = {}
    var onOpenURL: () -> Void = {}

    @State private var isHovered = false
    @State private var showPreview = false

    private var hasFile: Bool {
        guard let url = item.resolvedFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
                    .transition(.scale.combined(with: .opacity))
            }

            ThumbnailView(item: item, size: 44, cornerRadius: 9)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                    Text(displayTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 8) {
                    Text(item.sourceApp)
                        .lineLimit(1)
                    rowDot
                    Text(item.formattedDate)
                        .monospacedDigit()
                    rowDot
                    Text(item.descriptiveTag)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(.secondary.opacity(0.14))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.secondary.opacity(0.18), lineWidth: 0.5)
                        )
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if isHovered && !isSelectionMode {
                actionBar
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.regularMaterial)
                    .opacity(isHovered ? 0.95 : 0.55)
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.10))
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(0.045))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: (isHovered || isSelected) ? 1 : 0.5)
        )
        .shadow(
            color: isHovered ? Color.accentColor.opacity(0.12) : .black.opacity(0.03),
            radius: isHovered ? 6 : 2,
            y: isHovered ? 2 : 1
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var borderColor: Color {
        if isSelected { return Color.accentColor }
        if isHovered  { return Color.accentColor.opacity(0.55) }
        return Color.secondary.opacity(0.15)
    }

    private var rowDot: some View {
        Circle()
            .fill(.tertiary)
            .frame(width: 2.5, height: 2.5)
            .opacity(0.7)
    }

    private var displayTitle: String {
        // Merged entries set a preview prefixed with "[合并 N …]" — keep that
        // label as the title so the row visually reads as a merge result
        // instead of mirroring the first source item.
        if let preview = item.preview, preview.hasPrefix("[合并 ") {
            return preview.components(separatedBy: .newlines).first ?? preview
        }
        if let url = item.resolvedFileURL { return url.lastPathComponent }
        let firstLine = (item.preview ?? item.content)
            .components(separatedBy: .newlines)
            .first ?? ""
        return firstLine.isEmpty ? item.itemType.displayName : firstLine
    }

    private var actionBar: some View {
        HStack(spacing: 4) {
            HoverIconButton(
                systemName: "doc.on.doc",
                help: "复制",
                action: onCopy
            )
            HoverIconButton(
                systemName: "eye",
                help: "预览",
                action: { showPreview = true }
            )
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                PreviewPopover(item: item)
            }
            HoverIconButton(
                systemName: item.isPinned ? "pin.fill" : "pin",
                help: item.isPinned ? "取消置顶" : "置顶",
                tint: item.isPinned ? .orange : nil,
                action: onTogglePin
            )
            HoverIconButton(
                systemName: item.isFavorite ? "star.fill" : "star",
                help: item.isFavorite ? "取消收藏" : "收藏",
                tint: item.isFavorite ? .yellow : nil,
                action: onToggleFavorite
            )
            if item.itemType == .url {
                HoverIconButton(
                    systemName: "safari",
                    help: "在浏览器中打开",
                    action: onOpenURL
                )
            }
            if hasFile {
                HoverIconButton(
                    systemName: "folder",
                    help: "在 Finder 中显示",
                    action: onRevealInFinder
                )
                HoverIconButton(
                    systemName: "arrow.up.forward.app",
                    help: "打开文件",
                    action: onOpenFile
                )
            }
            HoverIconButton(
                systemName: "trash",
                help: "删除",
                tint: .red,
                action: onDelete
            )
        }
    }
}

struct HoverIconButton: View {
    let systemName: String
    let help: String
    var tint: Color? = nil
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(foreground)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(background)
                )
                .scaleEffect(isPressed ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { isHovered = hovering }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeOut(duration: 0.08)) { isPressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.12)) { isPressed = false }
                }
        )
    }

    private var foreground: Color {
        let base = tint ?? .secondary
        return isHovered ? (tint ?? .primary) : base
    }

    private var background: Color {
        if !isHovered { return .clear }
        if let tint { return tint.opacity(0.18) }
        return Color.secondary.opacity(0.2)
    }
}
