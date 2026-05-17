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
    @AppStorage("pinnedCollapsed") private var pinnedCollapsed = false

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
                case .trash:
                    TrashPanelView()
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
        .sheet(isPresented: $vm.showSnippetEditor) {
            SnippetEditorView(
                onSave: { content, type, pinned in
                    vm.createSnippet(
                        content: content,
                        type: type,
                        pinned: pinned,
                        context: modelContext
                    )
                    vm.showSnippetEditor = false
                    ToastCenter.shared.show(
                        pinned ? L("snippet.savedAndPinned") : L("snippet.saved"),
                        systemImage: "square.and.pencil",
                        tint: .accentColor
                    )
                },
                onCancel: { vm.showSnippetEditor = false }
            )
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
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: vm.isSelectionMode)
            }
        }
    }

    private var selectionActionBar: some View {
        let selected = vm.orderedSelectedItems(filteredItems)
        let blockReason = vm.mergeBlockReason(selectedItems: selected)
        let canMerge = blockReason == nil
        let allSelected = !filteredItems.isEmpty && selected.count == filteredItems.count

        return HStack(spacing: 10) {
            Text(L("selection.selectedFormat", selected.count, filteredItems.count))
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
                title: allSelected ? L("selection.clear") : L("selection.selectAll")
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    if allSelected { vm.clearSelection() }
                    else { vm.selectAll(filteredItems) }
                }
            }
            SelectionBarButton(systemName: "arrow.triangle.2.circlepath", title: L("selection.invert")) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    vm.invertSelection(filteredItems)
                }
            }

            Divider().frame(height: 18).opacity(0.5)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    vm.exitSelectionMode()
                }
            } label: {
                Text(L("common.cancel"))
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
                let result = withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    vm.mergeSelected(selected, context: modelContext)
                }
                guard result != nil else {
                    ToastCenter.shared.show(
                        L("selection.mergeFailed"),
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                    return
                }
                let suffix = MergeSettingsStore.shared.deleteOriginals ? L("selection.mergedSuffix.deleted") : ""
                ToastCenter.shared.show(
                    L("selection.mergedFormat", selected.count) + suffix,
                    systemImage: "square.stack.3d.up.fill",
                    tint: .accentColor
                )
            } label: {
                Label(L("selection.mergeCountFormat", selected.count), systemImage: "square.stack.3d.up.fill")
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
                Text(L("main.title"))
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(0.2)
                HStack(spacing: 8) {
                    HeaderStat(value: "\(allItems.count)", label: L("main.stat.records"))
                    HeaderStatDivider()
                    HeaderStat(value: "\(allItems.filter { $0.isFavorite }.count)", label: L("main.stat.favorites"))
                    if stats.enabled {
                        HeaderStatDivider()
                        HeaderStat(value: "\(stats.todayCount())", label: L("main.stat.today"), tint: .accentColor)
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
                Text(L("common.allTypes")).tag(nil as ClipboardItemType?)
                ForEach(ClipboardItemType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type as ClipboardItemType?)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 128)

            ToolbarSearchField(
                text: $vm.searchText,
                semantic: $vm.semanticSearchEnabled,
                featureEnabled: vm.semanticFeatureEnabled,
                indexing: vm.isBackfillingEmbeddings
            )

            Spacer(minLength: 8)

            ToolbarIconButton(systemName: "square.and.pencil", help: L("toolbar.newSnippet")) {
                vm.showSnippetEditor = true
            }
            .keyboardShortcut("n", modifiers: .command)

            ToolbarIconButton(
                systemName: vm.isSelectionMode ? "checkmark.circle.fill" : "checkmark.circle",
                help: vm.isSelectionMode ? L("toolbar.exitSelection") : L("toolbar.selectAndMerge")
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if vm.isSelectionMode {
                        vm.exitSelectionMode()
                    } else {
                        vm.enterSelectionMode()
                    }
                }
            }

            ToolbarIconButton(systemName: "trash", help: L("toolbar.trash")) {
                nav.showTrash()
            }

            ToolbarIconButton(systemName: "chart.bar.xaxis", help: L("toolbar.stats")) {
                nav.showStats()
            }

            ToolbarIconButton(systemName: "gearshape", help: L("toolbar.settings")) {
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
        }
    }

    private var emptyStateTitle: String {
        if !vm.searchText.isEmpty { return L("main.empty.title.noMatch") }
        switch vm.selectedScope {
        case .all: return L("main.empty.title.all")
        case .favorites: return L("main.empty.title.favorites")
        }
    }

    private var emptyStateSubtitle: String {
        if !vm.searchText.isEmpty { return L("main.empty.subtitle.noMatch") }
        switch vm.selectedScope {
        case .all: return L("main.empty.subtitle.all")
        case .favorites: return L("main.empty.subtitle.favorites")
        }
    }

    /// Split filtered items into a pinned section + the rest, but only when
    /// the user is on the "全部" scope — inside "收藏" a section header
    /// would just be noise.
    private var splitItems: (pinned: [ClipboardItem], others: [ClipboardItem]) {
        let items = filteredItems
        guard vm.selectedScope == .all else { return ([], items) }
        return (items.filter { $0.isPinned }, items.filter { !$0.isPinned })
    }

    private var cardList: some View {
        let split = splitItems
        return ScrollView {
            LazyVStack(spacing: 8) {
                if !split.pinned.isEmpty {
                    pinnedHeader(count: split.pinned.count)
                    if !pinnedCollapsed {
                        ForEach(split.pinned) { item in
                            cardRow(for: item)
                        }
                    }
                }
                ForEach(split.others) { item in
                    cardRow(for: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, vm.isSelectionMode ? 80 : 14)
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func cardRow(for item: ClipboardItem) -> some View {
        ClipboardItemRow(
            item: item,
            isSelectionMode: vm.isSelectionMode,
            isSelected: vm.isSelected(item),
            onCopy: {
                vm.copyToClipboard(item)
                ToastCenter.shared.show(L("common.copied"))
            },
            onDelete: {
                vm.deleteItem(item, context: modelContext)
                ToastCenter.shared.show(L("common.deleted"), systemImage: "trash.fill", tint: .red)
            },
            onToggleFavorite: {
                let willFavorite = !item.isFavorite
                vm.toggleFavorite(item)
                ToastCenter.shared.show(
                    willFavorite ? L("action.favorited") : L("action.unfavorited"),
                    systemImage: "star.fill",
                    tint: .yellow
                )
            },
            onTogglePin: {
                let willPin = !item.isPinned
                vm.togglePin(item)
                ToastCenter.shared.show(
                    willPin ? L("action.pinned") : L("action.unpinned"),
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
            },
            onSaveImage: {
                ExportService.shared.exportItem(item)
            },
            onAddTag: { tag in
                vm.addTag(tag, to: item)
                try? modelContext.save()
            },
            onRemoveTag: { tag in
                vm.removeTag(tag, from: item)
                try? modelContext.save()
            }
        )
        .contextMenu { contextMenu(for: item) }
        // Mount only one tap gesture at a time. Having both a single- and a
        // double-tap on the same view makes SwiftUI delay the single tap
        // until it can rule out a second click — that's the lag we were
        // seeing on selection.
        .gesture(
            vm.isSelectionMode
                ? TapGesture(count: 1).onEnded {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                        vm.toggleSelection(item)
                    }
                }
                : TapGesture(count: 2).onEnded {
                    vm.copyToClipboard(item)
                    ToastCenter.shared.show(L("common.copied"))
                }
        )
    }

    private func pinnedHeader(count: Int) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { pinnedCollapsed.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                Text(L("main.pinnedCountFormat", count))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                Image(systemName: pinnedCollapsed ? "chevron.right" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.separator.opacity(0.25), lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func contextMenu(for item: ClipboardItem) -> some View {
        Button(L("action.copy"), systemImage: "doc.on.doc") {
            vm.copyToClipboard(item)
            ToastCenter.shared.show(L("common.copied"))
        }
        if item.itemType == .url {
            Divider()
            Button(L("action.openInBrowser"), systemImage: "safari") {
                openInBrowser(item.content)
            }
        }
        if item.resolvedFileURL != nil {
            Divider()
            Button(L("action.revealInFinder"), systemImage: "folder") {
                if let url = item.resolvedFileURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            Button(L("action.openFile"), systemImage: "arrow.up.forward.app") {
                if let url = item.resolvedFileURL {
                    NSWorkspace.shared.open(url)
                }
            }
            Button(L("action.openWith"), systemImage: "app.badge") {
                if let url = item.resolvedFileURL {
                    FileOpener.openWithChooser(url: url)
                }
            }
        }
        Divider()
        Button(item.isFavorite ? L("action.unfavorite") : L("action.favorite"),
               systemImage: item.isFavorite ? "star.slash" : "star") {
            let willFavorite = !item.isFavorite
            vm.toggleFavorite(item)
            ToastCenter.shared.show(
                willFavorite ? L("action.favorited") : L("action.unfavorited"),
                systemImage: "star.fill",
                tint: .yellow
            )
        }
        Button(item.isPinned ? L("action.unpin") : L("action.pin"),
               systemImage: item.isPinned ? "pin.slash" : "pin") {
            let willPin = !item.isPinned
            vm.togglePin(item)
            ToastCenter.shared.show(
                willPin ? L("action.pinned") : L("action.unpinned"),
                systemImage: "pin.fill",
                tint: .orange
            )
        }
        Divider()
        Button(L("action.exportOne"), systemImage: "square.and.arrow.up") {
            ExportService.shared.exportItem(item)
        }
        Divider()
        Button(L("action.delete"), systemImage: "trash", role: .destructive) {
            vm.deleteItem(item, context: modelContext)
            ToastCenter.shared.show(L("common.deleted"), systemImage: "trash.fill", tint: .red)
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
    /// Master feature toggle from settings — when false, the semantic
    /// segment hides entirely so the search bar collapses to plain text.
    var featureEnabled: Bool
    /// True while the VM is backfilling embeddings. Disables the semantic
    /// segment with a "building index" hint instead of letting users switch
    /// into a half-populated mode.
    var indexing: Bool

    @FocusState private var focused: Bool

    /// Active mode color — accent for full-text, purple for semantic so
    /// users can tell at a glance which mode is driving the results.
    private var tint: Color { semantic ? .purple : .accentColor }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(focused ? tint : .secondary)
                .animation(.easeOut(duration: 0.15), value: focused)
            TextField(semantic ? L("common.semanticSearch") : L("common.searchContent"), text: $text)
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
                .help(L("common.clearSearch"))
                .transition(.opacity)
            }
            if featureEnabled {
                Divider().frame(height: 12).opacity(0.4)
                SearchModeSegment(
                    icon: "text.magnifyingglass",
                    title: L("common.searchMode.full"),
                    isOn: !semantic,
                    tint: .accentColor
                ) {
                    withAnimation(.easeOut(duration: 0.15)) { semantic = false }
                }
                SearchModeSegment(
                    icon: indexing ? "hourglass" : "sparkle",
                    title: indexing
                        ? L("common.searchMode.indexing")
                        : L("common.searchMode.semantic"),
                    isOn: semantic && !indexing,
                    tint: .purple,
                    disabled: indexing,
                    showsSpinner: indexing
                ) {
                    if indexing {
                        ToastCenter.shared.show(
                            L("search.semantic.indexing.toast"),
                            systemImage: "hourglass",
                            tint: .orange
                        )
                        return
                    }
                    withAnimation(.easeOut(duration: 0.15)) { semantic = true }
                }
            }
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
                    focused ? tint.opacity(0.6) : Color.secondary.opacity(0.18),
                    lineWidth: focused ? 1 : 0.5
                )
        )
        .frame(maxWidth: 360)
        .animation(.easeOut(duration: 0.18), value: focused)
        .animation(.easeOut(duration: 0.18), value: semantic)
        .animation(.easeOut(duration: 0.18), value: indexing)
        .animation(.easeOut(duration: 0.18), value: featureEnabled)
        // If settings flip the feature off while we're in semantic mode,
        // fall back to plain text — otherwise the search bar would behave
        // semantically with no visible affordance.
        .onChange(of: featureEnabled) { _, isOn in
            if !isOn, semantic { semantic = false }
        }
        // Same idea while a backfill is in-flight: drop into text mode so
        // the user actually sees results until the index is ready.
        .onChange(of: indexing) { _, isOn in
            if isOn, semantic { semantic = false }
        }
    }
}

private struct SearchModeSegment: View {
    let icon: String
    let title: String
    let isOn: Bool
    let tint: Color
    /// When true, the segment looks dimmed and reads as non-interactive.
    /// The click handler still fires (the parent uses it to surface a toast
    /// explaining why the mode is currently unavailable).
    var disabled: Bool = false
    /// Replaces the icon with a tiny progress indicator so users can tell at
    /// a glance that the disabled state is "loading" rather than "broken".
    var showsSpinner: Bool = false
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if showsSpinner {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                        .frame(width: 12, height: 12)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        isOn
                            ? AnyShapeStyle(tint)
                            : AnyShapeStyle(hovering && !disabled
                                ? Color.secondary.opacity(0.18)
                                : Color.clear)
                    )
            )
            .opacity(disabled ? 0.6 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var foreground: Color {
        if disabled { return .secondary }
        if isOn { return .white }
        return hovering ? .primary : .secondary
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
        .accessibilityLabel(help)
        .hoverTip(help)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Hover tooltip

/// Lightweight hover tooltip that pops up faster than macOS's default
/// `.help(...)` (which sits behind a ~1.5s system delay). Renders a small
/// rounded label below the icon after `delay` seconds of sustained hover.
private struct HoverTipModifier: ViewModifier {
    let text: String
    let delay: TimeInterval

    @State private var hovering = false
    @State private var showTip = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovering in
                hovering = isHovering
                if isHovering {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        guard hovering else { return }
                        withAnimation(.easeOut(duration: 0.12)) { showTip = true }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) { showTip = false }
                }
            }
            .overlay(alignment: .bottom) {
                if showTip {
                    HoverTipBubble(text: text)
                        .fixedSize()
                        .offset(y: 24)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .zIndex(999)
                }
            }
    }
}

private struct HoverTipBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.black.opacity(0.85))
            )
    }
}

extension View {
    /// Faster hover tooltip than the system `.help(...)`. Default ~0.35s
    /// delay (vs. macOS's ~1.5s) so the label appears almost immediately.
    func hoverTip(_ text: String, delay: TimeInterval = 0.35) -> some View {
        modifier(HoverTipModifier(text: text, delay: delay))
    }
}
