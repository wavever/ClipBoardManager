import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let openMainWindow = Self(
        "openMainWindow",
        default: .init(.v, modifiers: [.command, .shift])
    )

    static let openQuickPaste = Self(
        "openQuickPaste",
        default: .init(.v, modifiers: [.command, .option])
    )
}

enum AppShortcut: String, CaseIterable, Identifiable {
    case openMainWindow
    case openQuickPaste

    var id: String { rawValue }

    var name: KeyboardShortcuts.Name {
        switch self {
        case .openMainWindow: return .openMainWindow
        case .openQuickPaste: return .openQuickPaste
        }
    }

    var displayName: String {
        switch self {
        case .openMainWindow: return L("settings.shortcut.openMainWindow")
        case .openQuickPaste: return L("settings.shortcut.openQuickPaste")
        }
    }

    var subtitle: String {
        switch self {
        case .openMainWindow: return L("settings.shortcut.openMainWindow.subtitle")
        case .openQuickPaste: return L("settings.shortcut.openQuickPaste.subtitle")
        }
    }
}
