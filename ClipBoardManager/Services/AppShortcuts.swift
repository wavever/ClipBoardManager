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
        case .openMainWindow: return "打开主窗口"
        case .openQuickPaste: return "弹出快速粘贴浮窗"
        }
    }

    var subtitle: String {
        switch self {
        case .openMainWindow: return "全局热键，激活主窗口并置前"
        case .openQuickPaste: return "在鼠标位置弹出浮窗，多选后自动粘贴到当前应用"
        }
    }
}
