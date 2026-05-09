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

    private var iconColor: Color {
        switch item.itemType {
        case .text: return .blue
        case .image: return .green
        case .video: return .purple
        case .file: return .orange
        case .url: return .cyan
        case .rtf: return .pink
        }
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
