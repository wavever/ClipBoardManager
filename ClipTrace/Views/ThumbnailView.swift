import SwiftUI
import AppKit

struct ThumbnailView: View {
    let item: ClipboardItem
    let size: CGFloat
    let cornerRadius: CGFloat

    @State private var image: NSImage?
    @State private var didAttemptLoad = false

    init(item: ClipboardItem, size: CGFloat = 36, cornerRadius: CGFloat = 6) {
        self.item = item
        self.size = size
        self.cornerRadius = cornerRadius
    }

    // Per-type warm muted palette. Replaces the previous saturated system
    // colors (.blue / .green / .purple / .orange / .cyan / .pink) — those
    // read as "AI tech" next to the sage accent. Each entry ships a light
    // and dark variant so contrast holds in both schemes.
    private var iconColor: Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
            switch item.itemType {
            case .text:  return isDark
                ? NSColor(srgbRed: 0.58, green: 0.67, blue: 0.75, alpha: 1)   // warm slate
                : NSColor(srgbRed: 0.44, green: 0.55, blue: 0.65, alpha: 1)
            case .image: return isDark
                ? NSColor(srgbRed: 0.68, green: 0.75, blue: 0.47, alpha: 1)   // olive
                : NSColor(srgbRed: 0.55, green: 0.62, blue: 0.37, alpha: 1)
            case .video: return isDark
                ? NSColor(srgbRed: 0.66, green: 0.61, blue: 0.77, alpha: 1)   // dusty lavender
                : NSColor(srgbRed: 0.55, green: 0.48, blue: 0.67, alpha: 1)
            case .file:  return isDark
                ? NSColor(srgbRed: 0.83, green: 0.57, blue: 0.46, alpha: 1)   // terracotta
                : NSColor(srgbRed: 0.75, green: 0.47, blue: 0.35, alpha: 1)
            case .url:   return isDark
                ? NSColor(srgbRed: 0.48, green: 0.70, blue: 0.70, alpha: 1)   // muted teal
                : NSColor(srgbRed: 0.36, green: 0.60, blue: 0.60, alpha: 1)
            case .rtf:   return isDark
                ? NSColor(srgbRed: 0.77, green: 0.58, blue: 0.58, alpha: 1)   // dusty rose
                : NSColor(srgbRed: 0.69, green: 0.47, blue: 0.47, alpha: 1)
            }
        })
    }

    private var canHaveThumbnail: Bool {
        switch item.itemType {
        case .image, .video, .file:
            return item.imageData != nil || item.resolvedFileURL != nil
        case .text, .url, .rtf:
            return false
        }
    }

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: item.itemType.icon)
                            .font(.system(size: size * 0.45))
                            .foregroundStyle(iconColor)
                    }
            }
        }
        .task(id: item.id) {
            guard !didAttemptLoad, canHaveThumbnail else { return }
            didAttemptLoad = true
            let target = CGSize(width: size * 2, height: size * 2)
            if let cached = ThumbnailLoader.shared.cached(for: item, size: target) {
                image = cached
                return
            }
            image = await ThumbnailLoader.shared.thumbnail(for: item, size: target)
        }
    }
}
