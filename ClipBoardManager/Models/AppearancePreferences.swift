import SwiftUI

/// User-facing appearance theme choice. `.system` follows macOS dark/light mode.
enum AppearanceTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light:  return L("settings.theme.light")
        case .dark:   return L("settings.theme.dark")
        case .system: return L("settings.theme.system")
        }
    }

    var icon: String {
        switch self {
        case .light:  return "sun.max"
        case .dark:   return "moon"
        case .system: return "desktopcomputer"
        }
    }

    /// `nil` means "let the system decide" — required so SwiftUI doesn't lock
    /// the colour scheme when the user picks "follow system".
    var colorScheme: ColorScheme? {
        switch self {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }
}

/// Preferred UI language. `.system` defers to the user's macOS language list.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zh        // 简体中文
    case en        // English

    var id: String { rawValue }

    /// Always shown in its *own* language so a user who accidentally flipped
    /// into English can still find their way back to 中文.
    var nativeName: String {
        switch self {
        case .system: return L("settings.language.system")
        case .zh:     return "中文"
        case .en:     return "English"
        }
    }

    /// `nil` lets SwiftUI inherit the system locale; otherwise we pin it.
    var locale: Locale? {
        switch self {
        case .system: return nil
        case .zh:     return Locale(identifier: "zh-Hans")
        case .en:     return Locale(identifier: "en")
        }
    }
}
