import SwiftUI
import SwiftData

struct MainWindowView: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var allItems: [ClipboardItem]
    @Environment(\.modelContext) private var modelContext
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    
    private var filteredItems: [ClipboardItem] {
        vm.filteredItems(allItems)
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Picker("类型", selection: $vm.selectedType) {
                        Text("全部").tag(nil as ClipboardItemType?)
                        ForEach(ClipboardItemType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type as ClipboardItemType?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    
                    Spacer()
                    
                    if !vm.selectedItems.isEmpty {
                        Text("\(vm.selectedItems.count) 项已选")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(role: .destructive) {
                            let toDelete = allItems.filter { vm.selectedItems.contains($0.id) }
                            vm.deleteItems(toDelete, context: modelContext)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .help("删除选中")
                    }
                    
                    Menu {
                        Button("全选") { vm.selectAll(filteredItems) }
                        Button("取消选择") { vm.deselectAll() }
                        Divider()
                        Button("清空历史", role: .destructive) {
                            vm.deleteAll(context: modelContext)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                // Item List
                List(selection: $vm.selectedItem) {
                    ForEach(filteredItems) { item in
                        ClipboardItemRow(item: item, isSelected: vm.selectedItems.contains(item.id))
                            .tag(item)
                            .contextMenu {
                                Button("复制", systemImage: "doc.on.doc") {
                                    vm.copyToClipboard(item)
                                }
                                Button(item.isFavorite ? "取消收藏" : "收藏", systemImage: item.isFavorite ? "star.slash" : "star") {
                                    vm.toggleFavorite(item)
                                }
                                Button(item.isPinned ? "取消置顶" : "置顶", systemImage: item.isPinned ? "pin.slash" : "pin") {
                                    vm.togglePin(item)
                                }
                                Divider()
                                Button("导出…", systemImage: "square.and.arrow.up") {
                                    ExportService.shared.exportItem(item)
                                }
                                Divider()
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    vm.deleteItem(item, context: modelContext)
                                }
                            }
                            .onTapGesture(count: 2) {
                                vm.copyToClipboard(item)
                            }
                    }
                }
                .listStyle(.inset)
            }
            .navigationTitle("剪贴板历史")
            .searchable(text: $vm.searchText, prompt: "搜索内容…")
        } detail: {
            if let item = vm.selectedItem {
                DetailView(item: item)
            } else {
                ContentUnavailableView(
                    "选择一条记录",
                    systemImage: "doc.on.clipboard",
                    description: Text("从左侧列表选择一条剪贴板记录以预览")
                )
            }
        }
        .onAppear {
            vm.startMonitoring(context: modelContext)
        }
        .onDisappear {
            vm.stopMonitoring()
        }
    }
}
