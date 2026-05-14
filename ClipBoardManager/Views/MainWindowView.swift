import SwiftUI
import SwiftData
import AppKit

struct MainWindowView: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Query(sort: \ClipboardItem.createdAt, order: .reverse) private var allItems: [ClipboardItem]
    @Environment(\.modelContext) private var modelContext

    @ObservedObject private var nav = AppNavigation.shared
    @ObservedObject private var toasts = ToastCenter.shared
    @ObservedObject private var stats = CopyStatsStore.shared

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
                case .stats:
                    StatsPanelView()
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
        // Single, restrained accent halo in the upper-left — avoids the
        // overlapping multi-gradient look that reads as generic.
        RadialGradient(
            colors: [Color.accentColor.opacity(0.10), Color.clear],
            center: UnitPoint(x: 0.08, y: -0.05),
            startRadius: 20,
            endRadius: 520
        )
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thickMaterial)
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, y: 6)
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1)
                    )
                    .frame(width: 36, height: 36)
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("剪贴板历史")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(0.2)
                HStack(spacing: 8) {
                    HeaderStat(value: "\(allItems.count)", label: "条记录")
                    HeaderStatDivider()
                    HeaderStat(value: "\(allItems.filter { $0.isFavorite }.count)", label: "收藏")
                    if stats.enabled {
                        HeaderStatDivider()
                        HeaderStat(value: "\(stats.todayCount())", label: "今日", tint: .accentColor)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Picker("", selection: $vm.selectedScope) {
                ForEach(ListScope.allCases) { scope in
                    Label(scope.displayName, systemImage: scope.icon).tag(scope)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 210)
            .controlSize(.regular)

            Picker("", selection: $vm.selectedType) {
                Text("全部类型").tag(nil as ClipboardItemType?)
                ForEach(ClipboardItemType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type as ClipboardItemType?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 128)

            ToolbarSearchField(text: $vm.searchText, semantic: $vm.semanticSearchEnabled)

            Spacer(minLength: 8)

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

            ToolbarIconButton(systemName: "chart.bar.xaxis", help: "活跃统计") {
                nav.showStats()
            }

            ToolbarIconButton(systemName: "gearshape", help: "设置") {
                nav.showSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    .frame(width: 110, height: 110)
                Circle()
                    .stroke(Color.accentColor.opacity(0.08), lineWidth: 1)
                    .frame(width: 150, height: 150)
                Image(systemName: emptyStateIcon)
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(Color.accentColor.opacity(0.85))
            }
            VStack(spacing: 6) {
                Text(emptyStateTitle)
                    .font(.system(size: 16, weight: .semibold))
                Text(emptyStateSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
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
                    // Mount only one tap gesture at a time. Having both a
                    // single- and a double-tap on the same view makes SwiftUI
                    // delay the single tap until it can rule out a second
                    // click — that's the lag we were seeing on selection.
                    .gesture(
                        vm.isSelectionMode
                            ? TapGesture(count: 1).onEnded {
                                vm.toggleSelection(item)
                            }
                            : TapGesture(count: 2).onEnded {
                                vm.copyToClipboard(item)
                                ToastCenter.shared.show("已复制")
                            }
                    )
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

// MARK: - Header stat chip

private struct HeaderStat: View {
    let value: String
    let label: String
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint ?? .primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}

private struct HeaderStatDivider: View {
    var body: some View {
        Circle()
            .fill(.tertiary)
            .frame(width: 2.5, height: 2.5)
            .opacity(0.6)
    }
}

// MARK: - Search field

private struct ToolbarSearchField: View {
    @Binding var text: String
    @Binding var semantic: Bool

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(focused ? Color.accentColor : .secondary)
                .animation(.easeOut(duration: 0.15), value: focused)
            TextField(semantic ? "语义搜索…" : "搜索内容…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($focused)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
            Divider().frame(height: 12).opacity(0.4)
            Button {
                withAnimation(.easeOut(duration: 0.15)) { semantic.toggle() }
            } label: {
                Image(systemName: semantic ? "sparkle" : "text.magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(semantic ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(semantic ? "切换到全文搜索" : "切换到语义搜索")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.regularMaterial)
                .opacity(focused ? 0.95 : 0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    focused ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.18),
                    lineWidth: focused ? 1 : 0.5
                )
        )
        .frame(maxWidth: 320)
        .animation(.easeOut(duration: 0.18), value: focused)
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
