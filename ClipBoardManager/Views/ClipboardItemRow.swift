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
    var onSaveImage: () -> Void = {}
    var onAddTag: (String) -> Void = { _ in }
    var onRemoveTag: (String) -> Void = { _ in }

    @State private var isHovered = false
    @State private var showPreview = false
    @State private var showTagEditor = false

    private var hasFile: Bool {
        guard let url = item.resolvedFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? Color.appAccent : Color.secondary.opacity(0.6))
                    .contentTransition(.symbolEffect(.replace))
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
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
                    HStack(spacing: 4) {
                        if item.sourceApp == L("remote.universalClipboard") {
                            Image(systemName: "iphone.and.arrow.forward")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color.appAccent)
                        }
                        Text(item.sourceApp)
                            .lineLimit(1)
                    }
                    rowDot
                    Text(item.formattedDate)
                        .monospacedDigit()
                    rowDot
                    HStack(spacing: 3) {
                        Image(systemName: item.itemType.icon)
                            .font(.system(size: 9, weight: .semibold))
                        Text(item.descriptiveTag)
                            .font(.system(size: 10, weight: .medium))
                    }
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
                    ForEach(item.tags, id: \.self) { tag in
                        HStack(spacing: 3) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 9, weight: .semibold))
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Color.appAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.appAccent.opacity(0.14))
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 0.5)
                        )
                    }
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
                        .fill(Color.appAccent.opacity(0.10))
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.appAccent.opacity(0.045))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: (isHovered || isSelected) ? 1 : 0.5)
        )
        .shadow(
            color: isHovered ? Color.appAccent.opacity(0.12) : .black.opacity(0.03),
            radius: isHovered ? 6 : 2,
            y: isHovered ? 2 : 1
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showTagEditor) {
            TagEditorPopover(
                item: item,
                onAdd: onAddTag,
                onRemove: onRemoveTag
            )
        }
    }

    private var borderColor: Color {
        if isSelected { return Color.appAccent }
        if isHovered  { return Color.appAccent.opacity(0.55) }
        return Color.secondary.opacity(0.15)
    }

    private var rowDot: some View {
        Circle()
            .fill(.tertiary)
            .frame(width: 2.5, height: 2.5)
            .opacity(0.7)
    }

    private var displayTitle: String {
        // Merged entries set a preview prefixed with a localized "[Merged ..."
        // (or "[合并 ...") tag — keep that as the title so the row visually
        // reads as a merge result instead of mirroring the first source item.
        if let preview = item.preview,
           preview.hasPrefix("[合并 ") || preview.hasPrefix("[Merged ") {
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
                help: L("action.copy"),
                action: onCopy
            )
            HoverIconButton(
                systemName: "text.viewfinder",
                help: L("action.preview"),
                action: { showPreview = true }
            )
            .popover(isPresented: $showPreview, arrowEdge: .trailing) {
                PreviewPopover(item: item)
            }
            HoverIconButton(
                systemName: item.isPinned ? "pin.fill" : "pin",
                help: item.isPinned ? L("action.unpin") : L("action.pin"),
                tint: item.isPinned ? .orange : nil,
                action: onTogglePin
            )
            HoverIconButton(
                systemName: item.isFavorite ? "star.fill" : "star",
                help: item.isFavorite ? L("action.unfavorite") : L("action.favorite"),
                tint: item.isFavorite ? .yellow : nil,
                action: onToggleFavorite
            )
            HoverIconButton(
                systemName: item.tags.isEmpty ? "tag" : "tag.fill",
                help: L("action.editTags"),
                tint: item.tags.isEmpty ? nil : .appAccent,
                action: { showTagEditor = true }
            )
            if item.itemType == .url {
                HoverIconButton(
                    systemName: "safari",
                    help: L("action.openInBrowser"),
                    action: onOpenURL
                )
            }
            if item.itemType == .image, item.imageData != nil {
                HoverIconButton(
                    systemName: "square.and.arrow.down",
                    help: L("action.saveImage"),
                    action: onSaveImage
                )
            }
            if hasFile {
                HoverIconButton(
                    systemName: "folder",
                    help: L("action.revealInFinder"),
                    action: onRevealInFinder
                )
                HoverIconButton(
                    systemName: "arrow.up.forward.app",
                    help: L("action.openFile"),
                    action: onOpenFile
                )
            }
            HoverIconButton(
                systemName: "trash",
                help: L("action.delete"),
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
        .accessibilityLabel(help)
        .hoverTip(help)
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
