import SwiftUI
import AppKit

struct ClipboardItemRow: View {
    let item: ClipboardItem
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

                HStack(spacing: 6) {
                    Text(item.sourceApp)
                    Text("·").foregroundStyle(.tertiary)
                    Text(item.formattedDate)
                    Text("·").foregroundStyle(.tertiary)
                    Text(item.descriptiveTag)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.secondary.opacity(0.18))
                        .clipShape(Capsule())
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if isHovered {
                actionBar
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .opacity(isHovered ? 0.95 : 0.6)
                if isHovered {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.10),
                                    Color.accentColor.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: isHovered ? 1.5 : 1)
        )
        .shadow(
            color: isHovered ? Color.accentColor.opacity(0.18) : .black.opacity(0.04),
            radius: isHovered ? 10 : 4,
            y: isHovered ? 3 : 1
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var borderColor: Color {
        isHovered ? .accentColor : .secondary.opacity(0.18)
    }

    private var displayTitle: String {
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
