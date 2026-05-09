import SwiftUI
import SwiftData

@main
struct ClipBoardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardVM = ClipboardViewModel()
    
    var body: some Scene {
        WindowGroup("ClipBoardManager") {
            MainWindowView()
                .environmentObject(clipboardVM)
                .modelContainer(for: ClipboardItem.self)
        }
        .defaultSize(width: 1000, height: 600)
        
        MenuBarExtra("ClipBoard", systemImage: "doc.on.clipboard") {
            MenuBarView()
                .environmentObject(clipboardVM)
                .modelContainer(for: ClipboardItem.self)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            PreferencesView()
                .environmentObject(clipboardVM)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKeyMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGlobalHotKey()
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
