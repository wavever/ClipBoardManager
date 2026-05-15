import SwiftUI
import SwiftData

@main
struct AppLauncher {
    static func main() {
        if CommandLine.arguments.dropFirst().contains("--mcp") {
            MCPServer.run()
            return
        }
        ClipBoardManagerApp.main()
    }
}

struct ClipBoardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardVM = ClipboardViewModel()

    @AppStorage("showInDock") private var showInDock = true
    @AppStorage("menuBarIcon") private var menuBarIcon = true
    @AppStorage("hideFromCapture") private var hideFromCapture = false

    var body: some Scene {
        WindowGroup("ClipBoardManager", id: "main") {
            MainWindowView()
                .environmentObject(clipboardVM)
                .modelContainer(for: ClipboardItem.self)
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

        MenuBarExtra("ClipBoard", systemImage: "doc.on.clipboard", isInserted: $menuBarIcon) {
            MenuBarView()
                .environmentObject(clipboardVM)
                .modelContainer(for: ClipboardItem.self)
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
    private var hotKeyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyInitialActivationPolicy()
        setupGlobalHotKey()
    }

    private func applyInitialActivationPolicy() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "showInDock") == nil {
            defaults.set(true, forKey: "showInDock")
        }
        let showInDock = defaults.bool(forKey: "showInDock")
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }

    private func setupGlobalHotKey() {
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == [.command, .shift] && event.keyCode == 9 { // V key
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.title == "ClipBoardManager" {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }
        }
    }

    deinit {
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
