import SwiftUI

struct PreferencesView: View {
    @AppStorage("maxRecords") private var maxRecords = 500
    @AppStorage("pollInterval") private var pollInterval = 1.0
    @AppStorage("excludedApps") private var excludedApps = ""
    @AppStorage("globalHotkey") private var globalHotkey = "⌘⇧V"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    
    var body: some View {
        TabView {
            GeneralSettings(
                maxRecords: $maxRecords,
                pollInterval: $pollInterval,
                launchAtLogin: $launchAtLogin,
                showInDock: $showInDock,
                menuBarIcon: $menuBarIcon
            )
            .tabItem {
                Label("通用", systemImage: "gear")
            }
            
            ShortcutSettings(globalHotkey: $globalHotkey)
            .tabItem {
                Label("快捷键", systemImage: "keyboard")
            }
            
            FilterSettings(excludedApps: $excludedApps)
            .tabItem {
                Label("过滤", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

struct GeneralSettings: View {
    @Binding var maxRecords: Int
    @Binding var pollInterval: Double
    @Binding var launchAtLogin: Bool
    @Binding var showInDock: Bool
    @Binding var menuBarIcon: Bool
    
    var body: some View {
        Form {
            Toggle("登录时启动", isOn: $launchAtLogin)
            Toggle("在 Dock 中显示", isOn: $showInDock)
            Toggle("显示菜单栏图标", isOn: $menuBarIcon)
            
            Divider()
            
            Stepper("最大记录数: \(maxRecords)", value: $maxRecords, in: 50...5000, step: 50)
            
            Picker("监听间隔", selection: $pollInterval) {
                Text("0.5 秒").tag(0.5)
                Text("1 秒").tag(1.0)
                Text("2 秒").tag(2.0)
                Text("5 秒").tag(5.0)
            }
        }
        .formStyle(.grouped)
    }
}

struct ShortcutSettings: View {
    @Binding var globalHotkey: String
    
    var body: some View {
        Form {
            LabeledContent("全局快捷键") {
                Text(globalHotkey)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            Text("默认快捷键为 ⌘⇧V，可在此自定义。重启应用后生效。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

struct FilterSettings: View {
    @Binding var excludedApps: String
    
    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 8) {
                Text("排除的应用（每行一个）")
                    .font(.headline)
                TextEditor(text: $excludedApps)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(height: 120)
                    .border(.quaternary)
            }
            
            Text("来自这些应用的剪贴板内容将不会被记录。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
