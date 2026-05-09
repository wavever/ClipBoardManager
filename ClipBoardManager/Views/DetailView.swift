import SwiftUI
import AVKit

struct DetailView: View {
    let item: ClipboardItem
    @State private var imageScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: item.itemType.icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                
                VStack(alignment: .leading) {
                    Text(item.itemType.displayName)
                        .font(.headline)
                    Text("\(item.sourceApp) · \(item.formattedDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(item.content, forType: .string)
                } label: {
                    Label("复制", systemImage: "doc.on.doc")
                }
                
                Button {
                    ExportService.shared.exportItem(item)
                } label: {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                switch item.itemType {
                case .text, .url:
                    TextEditor(text: .constant(item.content))
                        .font(.system(size: 13, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .rtf:
                    Text(item.content)
                        .font(.system(size: 13))
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    
                case .image:
                    if let data = item.imageData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(imageScale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        imageScale = max(0.5, min(value, 5.0))
                                    }
                            )
                            .padding()
                    } else {
                        ContentUnavailableView("无法加载图片", systemImage: "photo.badge.exclamationmark")
                    }
                    
                case .video:
                    if let path = item.fileURL, let url = URL(string: path) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .frame(minHeight: 300)
                            .padding()
                    } else {
                        ContentUnavailableView("无法加载视频", systemImage: "video.badge.exclamationmark")
                    }
                    
                case .file:
                    VStack(spacing: 16) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text(item.content)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(item.itemType.displayName + " 详情")
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
}
