import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct SettingsPanelView: View {
    @ObservedObject private var nav = AppNavigation.shared
    @State private var section: Section = .general

    @AppStorage("maxRecords") private var maxRecords = 500
    @AppStorage("pollInterval") private var pollInterval = 1.0
    @AppStorage("globalHotkey") private var globalHotkey = "⌘⇧V"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("menuBarIcon") private var menuBarIcon = true

    enum Section: String, CaseIterable, Identifiable {
        case general = "通用"
        case shortcut = "快捷键"
        case filter = "过滤"
        case merge = "合并"
        case data = "数据"
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 14)

            tabs
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            ScrollView {
                content
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 220)
                Spacer(minLength: 0)
            }
            .allowsHitTesting(false)
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: { nav.showList() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().strokeBorder(.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("返回")
            .keyboardShortcut(.escape, modifiers: [])

            Text("设置")
                .font(.system(size: 28, weight: .bold))

            Spacer()
        }
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { sec in
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { section = sec }
                } label: {
                    Text(sec.rawValue)
                        .font(.system(size: 12.5, weight: section == sec ? .semibold : .medium))
                        .foregroundStyle(section == sec ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            ZStack {
                                if section == sec {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(.background)
                                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                                }
                            }
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.secondary.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(.separator.opacity(0.3), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .general:
            GeneralSection(
                maxRecords: $maxRecords,
                pollInterval: $pollInterval,
                launchAtLogin: $launchAtLogin,
                showInDock: $showInDock,
                menuBarIcon: $menuBarIcon
            )
        case .shortcut:
            ShortcutSection(globalHotkey: $globalHotkey)
        case .filter:
            FilterSection()
        case .merge:
            MergeSection()
        case .data:
            DataSection()
        }
    }
}

// MARK: - Reusable card sections

struct SettingCard<Control: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var control: () -> Control

    init(title: String, subtitle: String? = nil, @ViewBuilder control: @escaping () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            control()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .opacity(0.7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - General

private struct GeneralSection: View {
    @Binding var maxRecords: Int
    @Binding var pollInterval: Double
    @Binding var launchAtLogin: Bool
    @Binding var showInDock: Bool
    @Binding var menuBarIcon: Bool

    @AppStorage("fdaOnboardingDismissed") private var fdaOnboardingDismissed = false
    @ObservedObject private var nav = AppNavigation.shared

    var body: some View {
        VStack(spacing: 14) {
            SettingCard(title: "完全磁盘访问", subtitle: "授权后读取桌面、下载、文稿等位置的文件不会再弹窗") {
                HStack(spacing: 10) {
                    Button {
                        FullDiskAccessOnboardingView.openFullDiskAccessPane()
                    } label: {
                        Label("打开系统设置", systemImage: "arrow.up.right.square")
                    }
                    Button {
                        fdaOnboardingDismissed = false
                        nav.showList()
                    } label: {
                        Label("重新查看引导", systemImage: "questionmark.circle")
                    }
                    Spacer()
                }
            }
            SettingCard(title: "登录时启动", subtitle: "登录系统时自动运行 ClipBoard Manager") {
                Toggle("", isOn: $launchAtLogin).labelsHidden().toggleStyle(.switch)
            }
            SettingCard(title: "在 Dock 中显示", subtitle: "关闭后应用以菜单栏方式存在，不占用 Dock") {
                Toggle("", isOn: $showInDock).labelsHidden().toggleStyle(.switch)
            }
            SettingCard(title: "显示菜单栏图标", subtitle: "在系统菜单栏右侧展示快捷入口") {
                Toggle("", isOn: $menuBarIcon).labelsHidden().toggleStyle(.switch)
            }
            SettingCard(title: "最大记录数", subtitle: "超过该上限时会自动清理最旧的内容") {
                HStack {
                    Text("\(maxRecords) 条")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                    Spacer()
                    Stepper("", value: $maxRecords, in: 50...5000, step: 50)
                        .labelsHidden()
                }
            }
            SettingCard(title: "监听间隔", subtitle: "降低间隔反应更快，但会增加 CPU 占用") {
                Picker("", selection: $pollInterval) {
                    Text("0.5 秒").tag(0.5)
                    Text("1 秒").tag(1.0)
                    Text("2 秒").tag(2.0)
                    Text("5 秒").tag(5.0)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
    }
}

// MARK: - Shortcut

private struct ShortcutSection: View {
    @Binding var globalHotkey: String

    var body: some View {
        SettingCard(title: "全局快捷键", subtitle: "默认 ⌘⇧V，重启应用后生效") {
            Text(globalHotkey)
                .font(.system(size: 14, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.secondary.opacity(0.18))
                )
        }
    }
}

// MARK: - Filter

private struct FilterSection: View {
    @ObservedObject private var store = FilterSettingsStore.shared

    var body: some View {
        VStack(spacing: 14) {
            appsCard
            typesCard
            textRulesCard
        }
    }

    private var appsCard: some View {
        SettingCard(title: "排除的应用", subtitle: "来自这些应用的复制内容不会被记录") {
            VStack(alignment: .leading, spacing: 8) {
                if store.excludedApps.isEmpty {
                    Text("尚未添加")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.excludedApps) { app in
                        HStack(spacing: 10) {
                            if let icon = appIcon(for: app.bundleId) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "app")
                                    .font(.system(size: 18))
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                    .font(.system(size: 13, weight: .medium))
                                Text(app.bundleId)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button {
                                store.excludedApps.removeAll { $0.bundleId == app.bundleId }
                                ToastCenter.shared.show("已移除应用：\(app.name)", systemImage: "minus.circle.fill", tint: .orange)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help("移除")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.background.opacity(0.5))
                        )
                    }
                }
                HStack {
                    Spacer()
                    Button {
                        addApp()
                    } label: {
                        Label("添加应用…", systemImage: "plus")
                    }
                }
            }
        }
    }

    private var typesCard: some View {
        SettingCard(title: "排除的类型", subtitle: "勾选后该类型的内容不会进入历史") {
            VStack(spacing: 6) {
                ForEach(ClipboardItemType.allCases, id: \.self) { type in
                    HStack {
                        Label(type.displayName, systemImage: type.icon)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { store.excludedTypes.contains(type) },
                            set: { isOn in
                                if isOn { store.excludedTypes.insert(type) }
                                else { store.excludedTypes.remove(type) }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var textRulesCard: some View {
        SettingCard(title: "文本规则", subtitle: "可添加多条规则；任一规则匹配即被过滤") {
            VStack(spacing: 8) {
                if store.textFilters.isEmpty {
                    Text("尚未添加")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach($store.textFilters) { $rule in
                        HStack(spacing: 8) {
                            Picker("", selection: $rule.mode) {
                                ForEach(TextFilterRule.Mode.allCases) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)

                            TextField("文本", text: $rule.text)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                store.textFilters.removeAll { $0.id == rule.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help("移除")
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button {
                        store.textFilters.append(TextFilterRule(mode: .contains, text: ""))
                    } label: {
                        Label("添加规则", systemImage: "plus")
                    }
                }
            }
        }
    }

    private func appIcon(for bundleId: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.title = "选择要排除的应用"
        panel.prompt = "添加"
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK else { return }

        var added = 0
        for url in panel.urls {
            let bundle = Bundle(url: url)
            let bundleId = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
            let name = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent
            if !store.excludedApps.contains(where: { $0.bundleId == bundleId }) {
                store.excludedApps.append(AppFilterEntry(bundleId: bundleId, name: name))
                added += 1
            }
        }
        if added > 0 {
            ToastCenter.shared.show("已添加 \(added) 个应用")
        }
    }
}

// MARK: - Merge

private struct MergeSection: View {
    @ObservedObject private var store = MergeSettingsStore.shared

    var body: some View {
        VStack(spacing: 14) {
            SettingCard(title: "合并后处理", subtitle: "开启后，合并将删除被选中的原条目；关闭则保留原条目") {
                Toggle("", isOn: $store.deleteOriginals)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingCard(
                title: "文本 / 链接 / 富文本 分隔符",
                subtitle: "选择「自定义」时，可使用 \\n 表示换行、\\t 表示制表符"
            ) {
                separatorEditor(
                    selection: $store.textSeparator,
                    custom: $store.textCustomSeparator,
                    placeholder: "例如：\\n--\\n"
                )
            }

            SettingCard(
                title: "文件 / 视频 分隔符",
                subtitle: "用于合并多条文件路径"
            ) {
                separatorEditor(
                    selection: $store.fileSeparator,
                    custom: $store.fileCustomSeparator,
                    placeholder: "例如：; "
                )
            }

            SettingCard(
                title: "图片合并",
                subtitle: "启用后即可对多张图片进行拼接（纵向或横向）"
            ) {
                VStack(spacing: 12) {
                    HStack {
                        Text("启用图片合并")
                            .font(.system(size: 13))
                        Spacer()
                        Toggle("", isOn: $store.enableImageMerge)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                    if store.enableImageMerge {
                        Divider().opacity(0.4)
                        HStack {
                            Text("方向").font(.system(size: 13))
                            Spacer()
                            Picker("", selection: $store.imageDirection) {
                                ForEach(ImageMergeDirection.allCases) { dir in
                                    Label(dir.displayName, systemImage: dir.icon).tag(dir)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                        HStack {
                            Text("背景色").font(.system(size: 13))
                            Spacer()
                            Picker("", selection: $store.imageBackground) {
                                ForEach(ImageMergeBackground.allCases) { bg in
                                    Text(bg.displayName).tag(bg)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }
                        HStack {
                            Text("间距")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(Int(store.imageSpacing)) px")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 50, alignment: .trailing)
                            Slider(value: $store.imageSpacing, in: 0...64, step: 1)
                                .frame(width: 180)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func separatorEditor(
        selection: Binding<MergeSeparatorPreset>,
        custom: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: selection) {
                ForEach(MergeSeparatorPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 160)

            if selection.wrappedValue == .custom {
                TextField(placeholder, text: custom)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text("预览：\(previewLabel(for: selection.wrappedValue))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func previewLabel(for preset: MergeSeparatorPreset) -> String {
        switch preset {
        case .doubleNewline: return "↵↵ (空行)"
        case .newline:       return "↵"
        case .space:         return "␣"
        case .comma:         return ", "
        case .semicolon:     return "; "
        case .tab:           return "→"
        case .custom:        return ""
        }
    }
}

// MARK: - Data (export / clear)

private struct DataSection: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var stats = CopyStatsStore.shared

    var body: some View {
        VStack(spacing: 14) {
            SettingCard(
                title: "记录拷贝次数",
                subtitle: "关闭后将不再统计新发生的复制行为，已有数据保留"
            ) {
                Toggle("", isOn: $stats.enabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            SettingCard(
                title: "导出历史",
                subtitle: "将完整剪贴板历史以 JSON 格式导出，便于备份或迁移"
            ) {
                HStack {
                    Spacer()
                    Button {
                        vm.showExportPanel = true
                    } label: {
                        Label("导出为 JSON…", systemImage: "square.and.arrow.up")
                    }
                }
            }

            SettingCard(
                title: "清空历史",
                subtitle: "删除所有剪贴板记录，操作无法撤销"
            ) {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        vm.deleteAll(context: modelContext)
                        ToastCenter.shared.show("已清空历史", systemImage: "trash.fill", tint: .red)
                    } label: {
                        Label("清空所有记录", systemImage: "trash")
                    }
                }
            }

            SettingCard(
                title: "清除统计",
                subtitle: "重置所有日期的复制次数计数，无法撤销"
            ) {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        stats.resetAll()
                        ToastCenter.shared.show("已清除统计", systemImage: "chart.bar.xaxis", tint: .red)
                    } label: {
                        Label("清除所有统计", systemImage: "trash")
                    }
                }
            }
        }
    }
}
