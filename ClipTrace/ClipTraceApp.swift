import SwiftUI
import SwiftData
import KeyboardShortcuts

@main
struct AppLauncher {
    static func main() {
        if CommandLine.arguments.dropFirst().contains("--mcp") {
            MCPServer.run()
            return
        }
        ClipTraceApp.main()
    }
}

struct ClipTraceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardVM = ClipboardViewModel()

    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    @AppStorage("hideFromCapture") private var hideFromCapture = false
    @AppStorage("appearanceTheme") private var appearanceThemeRaw = AppearanceTheme.system.rawValue
    @AppStorage("appLanguage") private var appLanguageRaw = AppLanguage.system.rawValue
    // Holding this `@AppStorage` on the root scene is what makes a palette
    // change trigger a body rebuild — `Color.appAccent` reads from the same
    // key, so descendants pick up the new colour on the next render pass.
    @AppStorage("accentPalette") private var accentPaletteRaw = AccentPalette.sage.rawValue

    private var appearanceTheme: AppearanceTheme {
        AppearanceTheme(rawValue: appearanceThemeRaw) ?? .system
    }
    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }
    private var accentPalette: AccentPalette {
        AccentPalette(rawValue: accentPaletteRaw) ?? .sage
    }

    var body: some Scene {
        WindowGroup("剪迹", id: "main") {
            MainWindowView()
                .environmentObject(clipboardVM)
                .modelContainer(AppContainer.shared)
                .preferredColorScheme(appearanceTheme.colorScheme)
                .environment(\.locale, appLanguage.locale ?? Locale.current)
                .tint(accentPalette.color)
                .onAppear {
                    applyActivationPolicy()
                    applyCaptureProtection()
                }
                .onChange(of: showInDock) { _, _ in
                    applyActivationPolicy()
                }
                .onChange(of: hideFromCapture) { _, _ in
                    applyCaptureProtection()
                }
        }
        .defaultSize(width: 1000, height: 640)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("ClipBoard", systemImage: "doc.on.clipboard", isInserted: $menuBarIcon) {
            MenuBarView()
                .environmentObject(clipboardVM)
                .modelContainer(AppContainer.shared)
                .preferredColorScheme(appearanceTheme.colorScheme)
                .environment(\.locale, appLanguage.locale ?? Locale.current)
                .tint(accentPalette.color)
        }
        .menuBarExtraStyle(.window)
    }

    /// Toggle `NSWindow.sharingType` on every app window so the clipboard
    /// history doesn't leak into screen recordings or shared screens when the
    /// user enables the privacy switch.
    private func applyCaptureProtection() {
        let type: NSWindow.SharingType = hideFromCapture ? .none : .readOnly
        for window in NSApp.windows {
            window.sharingType = type
        }
    }

    private func applyActivationPolicy() {
        let policy: NSApplication.ActivationPolicy = showInDock ? .regular : .accessory
        guard NSApp.activationPolicy() != policy else { return }

        // Remember the window that was focused so we can restore it after the
        // policy change (switching to .accessory makes AppKit briefly hand
        // focus to another app).
        let previousKeyWindow = NSApp.keyWindow
            ?? NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey })

        NSApp.setActivationPolicy(policy)

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            previousKeyWindow?.makeKeyAndOrderFront(nil)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        applyInitialActivationPolicy()
        setupGlobalHotKeys()
        DynamicIslandController.shared.setEnabled(
            DynamicIslandController.shared.isEnabled
        )
    }

    private func applyInitialActivationPolicy() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "showInDock") == nil {
            defaults.set(true, forKey: "showInDock")
        }
        let showInDock = defaults.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    private func setupGlobalHotKeys() {
        KeyboardShortcuts.onKeyUp(for: .openMainWindow) {
            Task { @MainActor in
                AppDelegate.openMainWindow()
            }
        }
        KeyboardShortcuts.onKeyUp(for: .openQuickPaste) {
            Task { @MainActor in
                QuickPasteController.shared.toggle()
            }
        }
    }

    @MainActor
    private static func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.title == "剪迹" {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}
