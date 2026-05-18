import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers
import KeyboardShortcuts

struct SettingsPanelView: View {
    @ObservedObject private var nav = AppNavigation.shared
    @State private var section: Section = .general

    @AppStorage("maxRecords") private var maxRecords = 500
    @AppStorage("pollInterval") private var pollInterval = 1.0
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    @AppStorage("hideFromCapture") private var hideFromCapture = false
    @AppStorage("trimTrailingWhitespaceOnCopy") private var trimTrailing = false
    @AppStorage("dynamicIslandEnabled") private var dynamicIslandEnabled = false
    @AppStorage("appearanceTheme") private var appearanceThemeRaw = AppearanceTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.system.rawValue

    enum Section: String, CaseIterable, Identifiable {
        case general
        case shortcut
        case filter
        case merge
        case mcp
        case data
        case about
        var id: Self { self }
        var localizedTitle: String {
            switch self {
            case .general:  return L("settings.tab.general")
            case .shortcut: return L("settings.tab.shortcut")
            case .filter:   return L("settings.tab.filter")
            case .merge:    return L("settings.tab.merge")
            case .mcp:      return L("settings.tab.mcp")
            case .data:     return L("settings.tab.data")
            case .about:    return L("settings.tab.about")
            }
        }
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
            .help(L("common.back"))
            .keyboardShortcut(.escape, modifiers: [])

            Text(L("settings.title"))
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
                    Text(sec.localizedTitle)
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
                menuBarIcon: $menuBarIcon,
                hideFromCapture: $hideFromCapture,
                trimTrailing: $trimTrailing,
                dynamicIslandEnabled: $dynamicIslandEnabled,
                appearanceThemeRaw: $appearanceThemeRaw,
                appLanguageRaw: $appLanguageRaw
            )
        case .shortcut:
            ShortcutSection()
        case .filter:
            FilterSection()
        case .merge:
            MergeSection()
        case .mcp:
            MCPSection()
        case .data:
            DataSection()
        case .about:
            AboutSection()
        }
    }
}

// MARK: - Reusable building blocks
//
// New row/group pattern (icon + title + subtitle on the left, control flush
// right) shared across every settings section so toggles, pickers and
// buttons line up consistently.

/// One row inside a `SettingsGroup` card — colored icon, title, optional
/// secondary subtitle, and a trailing control (Toggle / Picker / Button …).
struct SettingsRow<Trailing: View>: View {
    let icon: String?
    let iconTint: Color
    let title: String
    let subtitle: String?
    @ViewBuilder var trailing: () -> Trailing

    init(
        icon: String? = nil,
        iconTint: Color = .accentColor,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.icon = icon
        self.iconTint = iconTint
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if let icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(iconTint.opacity(0.16))
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconTint)
                }
                .frame(width: 32, height: 32)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Card container that groups related rows under an optional section header.
/// Children must be `SettingsRow` (or any view) and are automatically
/// separated by a thin divider, matching the design mockup.
struct SettingsGroup<Content: View>: View {
    let headerIcon: String?
    let headerTitle: String?
    let headerTint: Color
    @ViewBuilder var content: () -> Content

    init(
        icon: String? = nil,
        title: String? = nil,
        tint: Color = .accentColor,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.headerIcon = icon
        self.headerTitle = title
        self.headerTint = tint
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let headerTitle {
                HStack(spacing: 8) {
                    if let headerIcon {
                        Image(systemName: headerIcon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(headerTint)
                    }
                    Text(headerTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.leading, 4)
            }

            _VariadicView.Tree(SettingsGroupLayout()) {
                content()
            }
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
}

private struct SettingsGroupLayout: _VariadicView_MultiViewRoot {
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        let items = Array(children)
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { idx in
                items[idx]
                if idx < items.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                        .opacity(0.5)
                }
            }
        }
    }
}

/// Pill-style segmented selector used for language / theme pickers. Mirrors
/// the design mockup: a tinted rounded pill for the active option, plain
/// hover background for inactive ones.
struct SettingsSegmented<Value: Hashable>: View {
    struct Option: Identifiable {
        let value: Value
        let title: String
        let icon: String?
        var id: Value { value }
    }

    @Binding var selection: Value
    let options: [Option]
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options) { opt in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { selection = opt.value }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = opt.icon {
                            Image(systemName: icon)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        Text(opt.title)
                            .font(.system(size: 12.5, weight: selection == opt.value ? .semibold : .medium))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(selection == opt.value ? Color.white : Color.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(selection == opt.value ? AnyShapeStyle(tint) : AnyShapeStyle(Color.clear))
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
}

/// Standalone titled card — used for sections that don't fit the row layout
/// (free-form button clusters, full-width pickers, lists with add/remove).
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
                .font(.system(size: 14, weight: .semibold))
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
    @Binding var hideFromCapture: Bool
    @Binding var trimTrailing: Bool
    @Binding var dynamicIslandEnabled: Bool
    @Binding var appearanceThemeRaw: String
    @Binding var appLanguageRaw: String

    @AppStorage("fdaOnboardingDismissed") private var fdaOnboardingDismissed = false
    @ObservedObject private var nav = AppNavigation.shared
    @EnvironmentObject private var vm: ClipboardViewModel

    private var semanticFeatureBinding: Binding<Bool> {
        Binding(
            get: { vm.semanticFeatureEnabled },
            set: { vm.setSemanticFeatureEnabled($0) }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(rawValue: appLanguageRaw) ?? .system },
            set: { appLanguageRaw = $0.rawValue }
        )
    }
    private var themeBinding: Binding<AppearanceTheme> {
        Binding(
            get: { AppearanceTheme(rawValue: appearanceThemeRaw) ?? .system },
            set: { appearanceThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 18) {
            // Language picker — keep first so users can recover from accidental switches.
            SettingsGroup(icon: "globe", title: L("settings.language.title"), tint: .blue) {
                SettingsRow(
                    icon: "character.bubble",
                    iconTint: .blue,
                    title: L("settings.language.title"),
                    subtitle: L("settings.language.subtitle")
                ) {
                    SettingsSegmented(
                        selection: languageBinding,
                        options: [
                            .init(value: .zh,     title: "中文",    icon: nil),
                            .init(value: .en,     title: "English", icon: nil),
                            .init(value: .system, title: L("settings.language.system"), icon: nil),
                        ],
                        tint: .blue
                    )
                    .frame(width: 320)
                }
            }

            // Appearance theme.
            SettingsGroup(icon: "paintpalette", title: L("settings.theme.title"), tint: .purple) {
                SettingsRow(
                    icon: "moon.stars",
                    iconTint: .purple,
                    title: L("settings.theme.title"),
                    subtitle: L("settings.theme.subtitle")
                ) {
                    SettingsSegmented(
                        selection: themeBinding,
                        options: [
                            .init(value: .light,  title: L("settings.theme.light"),  icon: "sun.max"),
                            .init(value: .dark,   title: L("settings.theme.dark"),   icon: "moon"),
                            .init(value: .system, title: L("settings.theme.system"), icon: "desktopcomputer"),
                        ],
                        tint: .purple
                    )
                    .frame(width: 320)
                }
            }

            // Window behaviour.
            SettingsGroup(icon: "macwindow", title: L("settings.window.title"), tint: .blue) {
                SettingsRow(
                    icon: "power",
                    iconTint: .orange,
                    title: L("settings.window.launchAtLogin"),
                    subtitle: L("settings.window.launchAtLogin.subtitle")
                ) {
                    Toggle("", isOn: $launchAtLogin).labelsHidden().toggleStyle(.switch)
                }
                SettingsRow(
                    icon: "dock.rectangle",
                    iconTint: .blue,
                    title: L("settings.window.showInDock"),
                    subtitle: L("settings.window.showInDock.subtitle")
                ) {
                    Toggle("", isOn: $showInDock).labelsHidden().toggleStyle(.switch)
                }
                SettingsRow(
                    icon: "menubar.rectangle",
                    iconTint: .indigo,
                    title: L("settings.window.menuBarIcon"),
                    subtitle: L("settings.window.menuBarIcon.subtitle")
                ) {
                    Toggle("", isOn: $menuBarIcon).labelsHidden().toggleStyle(.switch)
                }
                SettingsRow(
                    icon: "eye.slash",
                    iconTint: .pink,
                    title: L("settings.window.hideFromCapture"),
                    subtitle: L("settings.window.hideFromCapture.subtitle")
                ) {
                    Toggle("", isOn: $hideFromCapture).labelsHidden().toggleStyle(.switch)
                }
                SettingsRow(
                    icon: "capsule.portrait",
                    iconTint: .teal,
                    title: L("settings.window.dynamicIsland"),
                    subtitle: L("settings.window.dynamicIsland.subtitle")
                ) {
                    Toggle("", isOn: $dynamicIslandEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: dynamicIslandEnabled) { _, newValue in
                            DynamicIslandController.shared.setEnabled(newValue)
                        }
                }
                SettingsRow(
                    icon: "scissors",
                    iconTint: .green,
                    title: L("settings.window.trimTrailing"),
                    subtitle: L("settings.window.trimTrailing.subtitle")
                ) {
                    Toggle("", isOn: $trimTrailing).labelsHidden().toggleStyle(.switch)
                }
            }

            // Storage.
            SettingsGroup(icon: "internaldrive", title: L("settings.storage.title"), tint: .indigo) {
                SettingsRow(
                    icon: "tray.full",
                    iconTint: .indigo,
                    title: L("settings.storage.maxRecords"),
                    subtitle: L("settings.storage.maxRecords.subtitle")
                ) {
                    MaxRecordsField(value: $maxRecords)
                }
                SettingsRow(
                    icon: "timer",
                    iconTint: .cyan,
                    title: L("settings.storage.pollInterval"),
                    subtitle: L("settings.storage.pollInterval.subtitle")
                ) {
                    Picker("", selection: $pollInterval) {
                        Text(L("settings.poll.halfSecond")).tag(0.5)
                        Text(L("settings.poll.oneSecond")).tag(1.0)
                        Text(L("settings.poll.twoSeconds")).tag(2.0)
                        Text(L("settings.poll.fiveSeconds")).tag(5.0)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 110)
                }
            }

            // Semantic search — toggles the entire feature and surfaces the
            // backfill progress so users know why the search bar's semantic
            // button is unavailable on first launch / after a clear.
            SettingsGroup(icon: "sparkle", title: L("settings.semantic.title"), tint: .purple) {
                SettingsRow(
                    icon: "wand.and.sparkles",
                    iconTint: .purple,
                    title: L("settings.semantic.toggle"),
                    subtitle: L("settings.semantic.subtitle")
                ) {
                    Toggle("", isOn: semanticFeatureBinding)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                if vm.isBackfillingEmbeddings {
                    SettingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconTint: .orange,
                        title: L("settings.semantic.indexing.title"),
                        subtitle: String(
                            format: L("settings.semantic.indexing.subtitle.format"),
                            vm.backfillCompleted,
                            vm.backfillTotal
                        )
                    ) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    }
                }
            }

            // Full Disk Access — free-form card; doesn't fit the row layout.
            SettingCard(
                title: L("settings.fda.title"),
                subtitle: L("settings.fda.subtitle")
            ) {
                HStack(spacing: 10) {
                    Button {
                        FullDiskAccessOnboardingView.openFullDiskAccessPane()
                    } label: {
                        Label(L("settings.fda.openPrefs"), systemImage: "arrow.up.right.square")
                    }
                    Button {
                        fdaOnboardingDismissed = false
                        nav.showList()
                    } label: {
                        Label(L("settings.fda.viewOnboarding"), systemImage: "questionmark.circle")
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Shortcut

private struct ShortcutSection: View {
    @State private var accessibilityTrusted: Bool = AutoPasteService.isTrusted

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroup(icon: "command", title: L("settings.shortcut.group.title"), tint: .accentColor) {
                ForEach(AppShortcut.allCases) { shortcut in
                    SettingsRow(
                        icon: shortcut.icon,
                        iconTint: .accentColor,
                        title: shortcut.displayName,
                        subtitle: shortcut.subtitle
                    ) {
                        HStack(spacing: 8) {
                            KeyboardShortcuts.Recorder(for: shortcut.name)
                            Button {
                                KeyboardShortcuts.reset(shortcut.name)
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.borderless)
                            .help(L("settings.shortcut.resetTooltip"))
                        }
                    }
                }
            }

            SettingsGroup(icon: "lock.shield", title: L("settings.shortcut.permission.title"), tint: .orange) {
                SettingsRow(
                    icon: accessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                    iconTint: accessibilityTrusted ? .green : .orange,
                    title: L("settings.shortcut.permission.accessibility"),
                    subtitle: L("settings.shortcut.permission.accessibility.subtitle")
                ) {
                    HStack(spacing: 8) {
                        Text(accessibilityTrusted
                             ? L("settings.shortcut.permission.granted")
                             : L("settings.shortcut.permission.notGranted"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Button {
                            AutoPasteService.requestTrust()
                            // Re-check on next runloop tick — the user typically
                            // toggles in System Settings then returns to the app.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                accessibilityTrusted = AutoPasteService.isTrusted
                            }
                        } label: {
                            Label(
                                accessibilityTrusted
                                    ? L("settings.shortcut.permission.recheck")
                                    : L("settings.shortcut.permission.grant"),
                                systemImage: accessibilityTrusted
                                    ? "arrow.clockwise"
                                    : "arrow.up.right.square"
                            )
                            .font(.system(size: 12))
                        }
                    }
                }
            }
        }
    }
}

private extension AppShortcut {
    var icon: String {
        switch self {
        case .openMainWindow: return "rectangle.inset.filled.on.rectangle"
        case .openQuickPaste: return "bolt.fill"
        }
    }
}

// MARK: - Filter

private struct FilterSection: View {
    @ObservedObject private var store = FilterSettingsStore.shared

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroup(icon: "link.badge.plus", title: L("settings.filter.link.title"), tint: .blue) {
                SettingsRow(
                    icon: "link",
                    iconTint: .blue,
                    title: L("settings.filter.stripTracking"),
                    subtitle: L("settings.filter.stripTracking.subtitle")
                ) {
                    Toggle("", isOn: $store.stripURLTracking)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            appsCard
            typesCard
            textRulesCard
        }
    }

    private var appsCard: some View {
        SettingCard(title: L("settings.filter.apps.title"), subtitle: L("settings.filter.apps.subtitle")) {
            VStack(alignment: .leading, spacing: 8) {
                if store.excludedApps.isEmpty {
                    Text(L("common.notSet"))
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
                                ToastCenter.shared.show(
                                    L("settings.filter.apps.removedFormat", app.name),
                                    systemImage: "minus.circle.fill",
                                    tint: .orange
                                )
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help(L("common.remove"))
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
                        Label(L("settings.filter.apps.addButton"), systemImage: "plus")
                    }
                }
            }
        }
    }

    private var typesCard: some View {
        SettingsGroup(icon: "square.grid.2x2", title: L("settings.filter.types.title"), tint: .pink) {
            ForEach(ClipboardItemType.allCases, id: \.self) { type in
                SettingsRow(
                    icon: type.icon,
                    iconTint: .pink,
                    title: type.displayName,
                    subtitle: nil
                ) {
                    Toggle("", isOn: Binding(
                        get: { store.excludedTypes.contains(type) },
                        set: { isOn in
                            if isOn { store.excludedTypes.insert(type) }
                            else { store.excludedTypes.remove(type) }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
            }
        }
    }

    private var textRulesCard: some View {
        SettingCard(title: L("settings.filter.textRules.title"), subtitle: L("settings.filter.textRules.subtitle")) {
            VStack(spacing: 8) {
                if store.textFilters.isEmpty {
                    Text(L("common.notSet"))
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

                            TextField(L("settings.filter.textRules.placeholder"), text: $rule.text)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                store.textFilters.removeAll { $0.id == rule.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .help(L("common.remove"))
                        }
                    }
                }
                HStack {
                    Spacer()
                    Button {
                        store.textFilters.append(TextFilterRule(mode: .contains, text: ""))
                    } label: {
                        Label(L("settings.filter.textRules.add"), systemImage: "plus")
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
        panel.title = L("settings.filter.apps.chooserTitle")
        panel.prompt = L("settings.filter.apps.chooserPrompt")
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
            ToastCenter.shared.show(L("settings.filter.apps.addedFormat", added))
        }
    }
}

// MARK: - Merge

private struct MergeSection: View {
    @ObservedObject private var store = MergeSettingsStore.shared

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroup(icon: "square.stack.3d.up", title: L("settings.merge.behavior.title"), tint: .accentColor) {
                SettingsRow(
                    icon: "trash",
                    iconTint: .red,
                    title: L("settings.merge.deleteOriginals"),
                    subtitle: L("settings.merge.deleteOriginals.subtitle")
                ) {
                    Toggle("", isOn: $store.deleteOriginals)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                SettingsRow(
                    icon: "photo.on.rectangle.angled",
                    iconTint: .accentColor,
                    title: L("settings.merge.enableImageMerge"),
                    subtitle: L("settings.merge.enableImageMerge.subtitle")
                ) {
                    Toggle("", isOn: $store.enableImageMerge)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            if store.enableImageMerge {
                SettingCard(
                    title: L("settings.merge.imageParams.title"),
                    subtitle: L("settings.merge.imageParams.subtitle")
                ) {
                    VStack(spacing: 12) {
                        HStack {
                            Text(L("settings.merge.imageParams.direction")).font(.system(size: 13))
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
                            Text(L("settings.merge.imageParams.background")).font(.system(size: 13))
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
                            Text(L("settings.merge.imageParams.spacing"))
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

            SettingCard(
                title: L("settings.merge.textSep.title"),
                subtitle: L("settings.merge.textSep.subtitle")
            ) {
                separatorEditor(
                    selection: $store.textSeparator,
                    custom: $store.textCustomSeparator,
                    placeholder: L("settings.merge.textSep.placeholder")
                )
            }

            SettingCard(
                title: L("settings.merge.fileSep.title"),
                subtitle: L("settings.merge.fileSep.subtitle")
            ) {
                separatorEditor(
                    selection: $store.fileSeparator,
                    custom: $store.fileCustomSeparator,
                    placeholder: L("settings.merge.fileSep.placeholder")
                )
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
                Text(L("settings.merge.previewFormat", previewLabel(for: selection.wrappedValue)))
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

// MARK: - MCP

private struct MCPSection: View {
    @AppStorage("mcpEnabled") private var mcpEnabled = true

    private var executablePath: String {
        Bundle.main.executablePath ?? ""
    }

    private var configJSON: String {
        """
        {
          "mcpServers": {
            "clipboard": {
              "command": "\(executablePath)",
              "args": ["--mcp"]
            }
          }
        }
        """
    }

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroup(icon: "network", title: L("settings.mcp.title"), tint: .blue) {
                SettingsRow(
                    icon: "switch.2",
                    iconTint: .blue,
                    title: L("settings.mcp.enable"),
                    subtitle: L("settings.mcp.enable.subtitle")
                ) {
                    Toggle("", isOn: $mcpEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            SettingCard(
                title: L("settings.mcp.config.title"),
                subtitle: L("settings.mcp.config.subtitle")
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(configJSON)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.background.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.separator.opacity(0.4), lineWidth: 0.5)
                        )

                    HStack {
                        Spacer()
                        Button {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(configJSON, forType: .string)
                            ToastCenter.shared.show(
                                L("settings.mcp.copied"),
                                systemImage: "doc.on.clipboard.fill",
                                tint: .accentColor
                            )
                        } label: {
                            Label(L("settings.mcp.copyButton"), systemImage: "doc.on.clipboard")
                        }
                    }
                }
            }
        }
        .opacity(mcpEnabled ? 1 : 0.6)
    }
}

// MARK: - Data (export / clear)

private struct DataSection: View {
    @EnvironmentObject var vm: ClipboardViewModel
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var stats = CopyStatsStore.shared
    @ObservedObject private var filters = FilterSettingsStore.shared

    private var retentionOptions: [(value: Int, label: String)] {
        [
            (0, L("retention.forever")), (1, L("retention.oneDay")), (7, L("retention.sevenDays")),
            (30, L("retention.thirtyDays")), (90, L("retention.ninetyDays")), (180, L("retention.oneEightyDays"))
        ]
    }

    private var trashRetentionOptions: [(value: Int, label: String)] {
        [
            (1, L("retention.oneDay")), (3, L("retention.threeDays")), (7, L("retention.sevenDays")),
            (14, L("retention.fourteenDays")), (30, L("retention.thirtyDays")), (0, L("retention.forever"))
        ]
    }

    var body: some View {
        VStack(spacing: 18) {
            SettingsGroup(icon: "trash", title: L("settings.data.trash.title"), tint: .orange) {
                SettingsRow(
                    icon: "trash.circle",
                    iconTint: .orange,
                    title: L("settings.data.trash.enable"),
                    subtitle: L("settings.data.trash.enable.subtitle")
                ) {
                    Toggle("", isOn: $filters.trashEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
                if filters.trashEnabled {
                    SettingsRow(
                        icon: "clock.arrow.circlepath",
                        iconTint: .orange,
                        title: L("settings.data.trash.autoClean"),
                        subtitle: L("settings.data.trash.autoClean.subtitle")
                    ) {
                        Picker("", selection: $filters.trashRetentionDays) {
                            ForEach(trashRetentionOptions, id: \.value) { opt in
                                Text(opt.label).tag(opt.value)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 110)
                    }
                }
            }

            SettingsGroup(icon: "chart.bar.xaxis", title: L("settings.data.stats.title"), tint: .accentColor) {
                SettingsRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconTint: .accentColor,
                    title: L("settings.data.stats.recordCopy"),
                    subtitle: L("settings.data.stats.recordCopy.subtitle")
                ) {
                    Toggle("", isOn: $stats.enabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            SettingCard(
                title: L("settings.data.retention.title"),
                subtitle: L("settings.data.retention.subtitle")
            ) {
                VStack(spacing: 6) {
                    ForEach(ClipboardItemType.allCases, id: \.self) { type in
                        HStack {
                            Label(type.displayName, systemImage: type.icon)
                                .font(.system(size: 13))
                            Spacer()
                            Picker("", selection: retentionBinding(for: type)) {
                                ForEach(retentionOptions, id: \.value) { opt in
                                    Text(opt.label).tag(opt.value)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 110)
                        }
                        .padding(.vertical, 3)
                    }
                    HStack {
                        Spacer()
                        Button {
                            vm.applyRetentionCleanup(context: modelContext)
                            ToastCenter.shared.show(L("settings.data.retention.cleaned"), systemImage: "wand.and.sparkles", tint: .accentColor)
                        } label: {
                            Label(L("settings.data.retention.cleanNow"), systemImage: "wand.and.sparkles")
                        }
                    }
                    .padding(.top, 4)
                }
            }

            SettingCard(
                title: L("settings.data.export.title"),
                subtitle: L("settings.data.export.subtitle")
            ) {
                HStack(spacing: 10) {
                    Button {
                        vm.showExportPanel = true
                    } label: {
                        Label(L("settings.data.export.exportButton"), systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button(role: .destructive) {
                        vm.deleteAll(context: modelContext)
                        ToastCenter.shared.show(L("settings.data.export.clearedHistory"), systemImage: "trash.fill", tint: .red)
                    } label: {
                        Label(L("settings.data.export.clearHistory"), systemImage: "trash")
                    }
                    Button(role: .destructive) {
                        stats.resetAll()
                        ToastCenter.shared.show(L("settings.data.export.clearedStats"), systemImage: "chart.bar.xaxis", tint: .red)
                    } label: {
                        Label(L("settings.data.export.clearStats"), systemImage: "chart.bar.xaxis")
                    }
                }
            }
        }
    }

    private func retentionBinding(for type: ClipboardItemType) -> Binding<Int> {
        Binding(
            get: { filters.retentionDays(for: type) },
            set: { filters.setRetentionDays($0, for: type) }
        )
    }
}

// MARK: - About

private struct AboutSection: View {
    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "ClipBoard Manager"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var copyright: String {
        Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String ?? ""
    }

    private var appIcon: NSImage {
        NSImage(named: NSImage.applicationIconName)
            ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
    }

    var body: some View {
        VStack(spacing: 18) {
            SettingCard(title: appName, subtitle: nil) {
                HStack(spacing: 16) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 72, height: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appName)
                            .font(.system(size: 18, weight: .semibold))
                        Text(L("settings.about.versionFormat", version, build))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                        if !copyright.isEmpty {
                            Text(copyright)
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            SettingsGroup(icon: "info.circle", title: L("settings.about.info.title"), tint: .blue) {
                SettingsRow(
                    icon: "number",
                    iconTint: .blue,
                    title: L("settings.about.version"),
                    subtitle: nil
                ) {
                    Text(version)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                SettingsRow(
                    icon: "hammer",
                    iconTint: .indigo,
                    title: L("settings.about.build"),
                    subtitle: nil
                ) {
                    Text(build)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                SettingsRow(
                    icon: "shippingbox",
                    iconTint: .teal,
                    title: L("settings.about.bundleId"),
                    subtitle: nil
                ) {
                    Text(Bundle.main.bundleIdentifier ?? "—")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                SettingsRow(
                    icon: "desktopcomputer",
                    iconTint: .purple,
                    title: L("settings.about.system"),
                    subtitle: nil
                ) {
                    Text(systemVersionString())
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            SettingsGroup(icon: "link", title: L("settings.about.links.title"), tint: .green) {
                SettingsRow(
                    icon: "chevron.left.forwardslash.chevron.right",
                    iconTint: .green,
                    title: L("settings.about.repo"),
                    subtitle: Self.repoURL.absoluteString
                ) {
                    Button {
                        NSWorkspace.shared.open(Self.repoURL)
                    } label: {
                        Label(L("settings.about.repo.open"), systemImage: "arrow.up.right.square")
                            .font(.system(size: 12))
                    }
                }
                SettingsRow(
                    icon: "exclamationmark.bubble",
                    iconTint: .red,
                    title: L("settings.about.feedback"),
                    subtitle: L("settings.about.feedback.subtitle")
                ) {
                    Button {
                        NSWorkspace.shared.open(Self.issuesURL)
                    } label: {
                        Label(L("settings.about.feedback.open"), systemImage: "arrow.up.right.square")
                            .font(.system(size: 12))
                    }
                }
                SettingsRow(
                    icon: "doc.text",
                    iconTint: .orange,
                    title: L("settings.about.license"),
                    subtitle: L("settings.about.license.subtitle")
                ) {
                    Button {
                        NSWorkspace.shared.open(Self.licenseURL)
                    } label: {
                        Label("MIT", systemImage: "arrow.up.right.square")
                            .font(.system(size: 12))
                    }
                }
            }

            SettingCard(
                title: L("settings.about.acknowledgements.title"),
                subtitle: L("settings.about.acknowledgements.subtitle")
            ) {
                Text(L("settings.about.acknowledgements.body"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static let repoURL = URL(string: "https://github.com/wavever/ClipBoardManager")!
    private static let licenseURL = URL(string: "https://github.com/wavever/ClipBoardManager/blob/main/LICENSE")!
    private static let issuesURL = URL(string: "https://github.com/wavever/ClipBoardManager/issues")!

    private func systemVersionString() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
}

// MARK: - Max records field
//
// A numeric input that lets the user type any value within `range` directly.
// Commits on Return / focus loss and clamps out-of-range entries; a non-numeric
// entry reverts to the last valid value so the UI never holds an invalid state.
private struct MaxRecordsField: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 50...100_000

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 6) {
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .focused($focused)
                .onAppear { text = "\(value)" }
                .onChange(of: value) { _, newValue in
                    if !focused { text = "\(newValue)" }
                }
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { commit() }
                }
                .onSubmit { commit() }
            Text(L("settings.storage.maxRecordsUnit"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    private func commit() {
        let digits = text.filter(\.isNumber)
        if let parsed = Int(digits) {
            let clamped = min(max(parsed, range.lowerBound), range.upperBound)
            value = clamped
            text = "\(clamped)"
        } else {
            // Reject empty / non-numeric — fall back to the last good value.
            text = "\(value)"
        }
    }
}
