import SwiftUI
import SwiftData

struct MenuBarView: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var allItems: [ClipboardItem]
    @State private var searchText = ""
    
    private var recentItems: [ClipboardItem] {
        let items = Array(allItems.prefix(20))
        if searchText.isEmpty { return items }
        return items.filter {
            $0.content.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(.blue)
                Text("剪贴板历史")
                    .font(.headline)
                Spacer()
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference") {
                        NSWorkspace.shared.open(url)
                    }
                    // Open main window
                    for window in NSApp.windows where window.title == "ClipBoardManager" {
                        window.makeKeyAndOrderFront(nil)
                        break
                    }
                    if NSApp.windows.isEmpty || !NSApp.windows.contains(where: { $0.title == "ClipBoardManager" }) {
                        // Fallback: activate app
                        NSApp.activate(ignoringOtherApps: true)
                    }
                } label: {
                    Image(systemName: "macwindow")
                }
                .buttonStyle(.borderless)
                .help("打开主窗口")
            }
            .padding(12)
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            Divider()
            
            // Recent Items
            if recentItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("暂无记录")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(recentItems) { item in
                            MenuBarRow(item: item)
                                .onTapGesture(count: 2) {
                                    vm.copyToClipboard(item)
                                }
                        }
                    }
                    .padding(4)
                }
                .frame(maxHeight: 400)
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("\(allItems.count) 条记录")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("清空") {
                    // Would need modelContext
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .padding(8)
        }
        .frame(width: 320)
    }
}

struct MenuBarRow: View {
    let item: ClipboardItem
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.itemType.icon)
                .font(.system(size: 12))
                .foregroundStyle(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.preview ?? item.content)
                    .font(.system(size: 12))
                    .lineLimit(1)
                Text(item.formattedDate)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .clipShape(RoundedRectangle(cornerRadius: 4))
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
