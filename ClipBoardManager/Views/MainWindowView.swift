import SwiftUI
import SwiftData
import AppKit

struct MainWindowView: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var allItems: [ClipboardItem]
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var nav = AppNavigation.shared
    @ObservedObject private var toasts = ToastCenter.shared

    @AppStorage("fdaOnboardingDismissed") private var fdaOnboardingDismissed = false

    private var filteredItems: [ClipboardItem] {
        vm.filteredItems(allItems)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .ignoresSafeArea()

            backgroundDecoration
                .allowsHitTesting(false)

            Group {
                switch nav.screen {
                case .list:
                    listScreen
                case .settings:
                    SettingsPanelView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .animation(.easeOut(duration: 0.22), value: nav.screen)

            if let toast = toasts.current {
                ToastView(toast: toast) { toasts.dismiss() }
                    .padding(.top, 14)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .id(toast.id)
            }

            if !fdaOnboardingDismissed {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            fdaOnboardingDismissed = true
                        }
                    }
                    .transition(.opacity)
                    .zIndex(2)

                FullDiskAccessOnboardingView {
                    withAnimation(.easeOut(duration: 0.2)) {
                        fdaOnboardingDismissed = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(3)
            }
        }
        .animation(.easeOut(duration: 0.22), value: fdaOnboardingDismissed)
        .onAppear {
            vm.startMonitoring(context: modelContext)
            vm.backfillEmbeddings(context: modelContext)
        }
        .onDisappear {
            vm.stopMonitoring()
        }
        .sheet(isPresented: $vm.showExportPanel) {
            ExportPanelView(allItems: allItems) {
                vm.showExportPanel = false
            }
        }
    }

    private var backgroundDecoration: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.10),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.purple.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var listScreen: some View {
        VStack(spacing: 0) {
            header
            toolbar
                .background(
                    Rectangle()
                        .fill(.regularMaterial)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(.separator.opacity(0.5))
                                .frame(height: 0.5)
                        }
                )

            if filteredItems.isEmpty {
                emptyState
            } else {
                ZStack(alignment: .bottom) {
                    cardList
                    if vm.isSelectionMode {
                        selectionActionBar
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.18), value: vm.isSelectionMode)
                .animation(.easeOut(duration: 0.18), value: vm.selectedItemIDs)
            }
        }
    }

    private var selectionActionBar: some View {
        let selected = vm.orderedSelectedItems(filteredItems)
        let blockReason = vm.mergeBlockReason(selectedItems: selected)
        let canMerge = blockReason == nil
        let allSelected = !filteredItems.isEmpty && selected.count == filteredItems.count

        return HStack(spacing: 10) {
            Text("已选 \(selected.count)/\(filteredItems.count)")
                .font(.system(size: 13, weight: .semibold))
                .monospacedDigit()
            if let reason = blockReason, !selected.isEmpty {
                Text("·").foregroundStyle(.tertiary)
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            SelectionBarButton(
                systemName: allSelected ? "checkmark.circle.badge.xmark" : "checkmark.circle",
                title: allSelected ? "清空" : "全选"
            ) {
                if allSelected { vm.clearSelection() }
                else { vm.selectAll(filteredItems) }
            }
            SelectionBarButton(systemName: "arrow.triangle.2.circlepath", title: "反选") {
                vm.invertSelection(filteredItems)
            }

            Divider().frame(height: 18).opacity(0.5)

            Button {
                vm.exitSelectionMode()
            } label: {
                Text("取消")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.15))
            )

            Button {
                guard vm.mergeSelected(selected, context: modelContext) != nil else { return }
                let suffix = MergeSettingsStore.shared.deleteOriginals ? "（已删除原条目）" : ""
                ToastCenter.shared.show(
                    "已合并 \(selected.count) 条\(suffix)",
                    systemImage: "square.stack.3d.up.fill",
                    tint: .accentColor
                )
            } label: {
                Label("合并 \(selected.count) 条", systemImage: "square.stack.3d.up.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(canMerge ? Color.accentColor : Color.accentColor.opacity(0.35))
            )
            .disabled(!canMerge)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                    .shadow(color: .accentColor.opacity(0.3), radius: 6, y: 2)
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("剪贴板历史")
                    .font(.system(size: 18, weight: .bold))
                Text("\(allItems.count) 条记录 · \(allItems.filter { $0.isFavorite }.count) 收藏")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $vm.selectedScope) {
                ForEach(ListScope.allCases) { scope in
                    Label(scope.displayName, systemImage: scope.icon)
                        .tag(scope)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 200)

            Picker("", selection: $vm.selectedType) {
                Text("全部类型").tag(nil as ClipboardItemType?)
                ForEach(ClipboardItemType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type as ClipboardItemType?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 130)

            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                TextField(vm.semanticSearchEnabled ? "语义搜索…" : "搜索内容…", text: $vm.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                Divider().frame(height: 14).opacity(0.4)
                Button {
                    vm.semanticSearchEnabled.toggle()
                } label: {
                    Image(systemName: vm.semanticSearchEnabled ? "sparkle" : "text.magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(vm.semanticSearchEnabled ? Color.purple : Color.secondary)
                        .help(vm.semanticSearchEnabled ? "切换到全文搜索" : "切换到语义搜索")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
            )
            .frame(maxWidth: 320)

            Spacer()

            ToolbarIconButton(
                systemName: vm.isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle",
                help: vm.isSelectionMode ? "退出选择" : "选择并合并"
            ) {
                if vm.isSelectionMode {
                    vm.exitSelectionMode()
                } else {
                    vm.enterSelectionMode()
                }
            }

            ToolbarIconButton(systemName: "gearshape", help: "设置") {
                nav.showSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Menu {
                Button("导出为 JSON…", systemImage: "square.and.arrow.up") {
                    vm.showExportPanel = true
                }
                Divider()
                Button("清空历史", role: .destructive) {
                    vm.deleteAll(context: modelContext)
                    ToastCenter.shared.show("已清空历史", systemImage: "trash.fill", tint: .red)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 30, height: 30)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 30, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.18), .accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(Color.accentColor)
            }
            Text(emptyStateTitle)
                .font(.system(size: 15, weight: .semibold))
            Text(emptyStateSubtitle)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateIcon: String {
        if !vm.searchText.isEmpty { return "magnifyingglass" }
        switch vm.selectedScope {
        case .all: return "tray"
        case .favorites: return "star"
        case .pinned: return "pin"
        }
    }

    private var emptyStateTitle: String {
        if !vm.searchText.isEmpty { return "未找到匹配的内容" }
        switch vm.selectedScope {
        case .all: return "暂无剪贴板记录"
        case .favorites: return "还没有收藏的内容"
        case .pinned: return "还没有置顶的内容"
        }
    }

    private var emptyStateSubtitle: String {
        if !vm.searchText.isEmpty { return "试试其他关键字或类型" }
        switch vm.selectedScope {
        case .all: return "复制点什么试试 — 文本、图片、文件都可以"
        case .favorites: return "在条目上点 ☆ 即可加入收藏"
        case .pinned: return "在条目上点 📌 即可置顶"
        }
    }

    private var cardList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        isSelectionMode: vm.isSelectionMode,
                        isSelected: vm.isSelected(item),
                        onCopy: {
                            vm.copyToClipboard(item)
                            ToastCenter.shared.show("已复制")
                        },
                        onDelete: {
                            vm.deleteItem(item, context: modelContext)
                            ToastCenter.shared.show("已删除", systemImage: "trash.fill", tint: .red)
                        },
                        onToggleFavorite: {
                            let willFavorite = !item.isFavorite
                            vm.toggleFavorite(item)
                            ToastCenter.shared.show(
                                willFavorite ? "已添加到收藏" : "已取消收藏",
                                systemImage: "star.fill",
                                tint: .yellow
                            )
                        },
                        onTogglePin: {
                            let willPin = !item.isPinned
                            vm.togglePin(item)
                            ToastCenter.shared.show(
                                willPin ? "已置顶" : "已取消置顶",
                                systemImage: "pin.fill",
                                tint: .orange
                            )
                        },
                        onRevealInFinder: {
                            if let url = item.resolvedFileURL {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        },
                        onOpenFile: {
                            if let url = item.resolvedFileURL {
                                NSWorkspace.shared.open(url)
                            }
                        },
                        onOpenURL: {
                            openInBrowser(item.content)
                        }
                    )
                    .contextMenu { contextMenu(for: item) }
                    .onTapGesture(count: 2) {
                        guard !vm.isSelectionMode else { return }
                        vm.copyToClipboard(item)
                        ToastCenter.shared.show("已复制")
                    }
                    .onTapGesture {
                        if vm.isSelectionMode {
                            vm.toggleSelection(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, vm.isSelectionMode ? 80 : 14)
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func contextMenu(for item: ClipboardItem) -> some View {
        Button("复制", systemImage: "doc.on.doc") {
            vm.copyToClipboard(item)
            ToastCenter.shared.show("已复制")
        }
        if item.itemType == .url {
            Divider()
            Button("在浏览器中打开", systemImage: "safari") {
                openInBrowser(item.content)
            }
        }
        if item.resolvedFileURL != nil {
            Divider()
            Button("在 Finder 中显示", systemImage: "folder") {
                if let url = item.resolvedFileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Button("打开文件", systemImage: "arrow.up.forward.app") {
                if let url = item.resolvedFileURL {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("用其他应用打开…", systemImage: "app.badge") {
                if let url = item.resolvedFileURL {
                    FileOpener.openWithChooser(url: url)
                }
            }
        }
        Divider()
        Button(item.isFavorite ? "取消收藏" : "收藏",
               systemImage: item.isFavorite ? "star.slash" : "star") {
            let willFavorite = !item.isFavorite
            vm.toggleFavorite(item)
            ToastCenter.shared.show(
                willFavorite ? "已添加到收藏" : "已取消收藏",
                systemImage: "star.fill",
                tint: .yellow
            )
        }
        Button(item.isPinned ? "取消置顶" : "置顶",
               systemImage: item.isPinned ? "pin.slash" : "pin") {
            let willPin = !item.isPinned
            vm.togglePin(item)
            ToastCenter.shared.show(
                willPin ? "已置顶" : "已取消置顶",
                systemImage: "pin.fill",
                tint: .orange
            )
        }
        Divider()
        Button("导出…", systemImage: "square.and.arrow.up") {
            ExportService.shared.exportItem(item)
        }
        Divider()
        Button("删除", systemImage: "trash", role: .destructive) {
            vm.deleteItem(item, context: modelContext)
            ToastCenter.shared.show("已删除", systemImage: "trash.fill", tint: .red)
        }
    }

    private func openInBrowser(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let candidate: String = {
            if trimmed.contains("://") { return trimmed }
            return "https://\(trimmed)"
        }()
        if let url = URL(string: candidate) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Selection bar button

private struct SelectionBarButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: systemName).font(.system(size: 11, weight: .semibold))
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(isHovered ? Color.primary : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isHovered ? Color.secondary.opacity(0.18) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Toolbar icon button

struct ToolbarIconButton: View {
    let systemName: String
    let help: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isHovered ? Color.secondary.opacity(0.18) : .clear)
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovered = $0 }
    }
}
