import AppKit
import ApplicationServices

/// Synthesises a ⌘V keystroke targeted at whatever app is currently frontmost.
/// Requires Accessibility permission; otherwise calls fall through silently and
/// callers should surface a toast.
@MainActor
enum AutoPasteService {
    /// `true` when the app already has Accessibility permission.
    nonisolated static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Show the system Accessibility prompt if we're not trusted yet.
    /// Does nothing when already trusted.
    static func requestTrust() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Post ⌘V to the system. Returns `false` if Accessibility is missing.
    @discardableResult
    static func paste() -> Bool {
        guard isTrusted else { return false }

        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09 // kVK_ANSI_V

        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        up?.flags = .maskCommand

        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
        return true
    }
}
