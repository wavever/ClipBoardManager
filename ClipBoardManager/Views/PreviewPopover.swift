import SwiftUI
import AVKit
import AppKit

struct PreviewPopover: View {
    let item: ClipboardItem

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: item.itemType.icon)
                    .foregroundStyle(.secondary)
                Text(item.itemType.displayName)
                    .font(.headline)
                Spacer()
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 360, idealWidth: 460, minHeight: 240, idealHeight: 320)
    }

    @ViewBuilder
    private var content: some View {
        switch item.itemType {
        case .text, .url:
            ScrollView {
                Text(item.content)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
            }
        case .rtf:
            ScrollView {
                Text(item.content)
                    .font(.system(size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(12)
            }
        case .image:
            if let img = imageToShow() {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                ContentUnavailableView("无法预览图片", systemImage: "photo.badge.exclamationmark")
            }
        case .video:
            if let url = item.resolvedFileURL, FileManager.default.fileExists(atPath: url.path) {
                VideoPlayer(player: AVPlayer(url: url))
                    .padding(8)
            } else {
                ContentUnavailableView("无法预览视频", systemImage: "video.badge.exclamationmark")
            }
        case .file:
            VStack(spacing: 12) {
                if let url = item.resolvedFileURL {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 96, height: 96)
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                    Text(url.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(item.content)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private func imageToShow() -> NSImage? {
        if let data = item.imageData, let img = NSImage(data: data) { return img }
        if let url = item.resolvedFileURL, let img = NSImage(contentsOf: url) { return img }
        return nil
    }
}
