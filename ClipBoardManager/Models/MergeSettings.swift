import Foundation
import SwiftUI

enum MergeSeparatorPreset: String, Codable, CaseIterable, Identifiable {
    case doubleNewline
    case newline
    case space
    case comma
    case semicolon
    case tab
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .doubleNewline: return "空行"
        case .newline:       return "换行"
        case .space:         return "空格"
        case .comma:         return "逗号"
        case .semicolon:     return "分号"
        case .tab:           return "制表符"
        case .custom:        return "自定义"
        }
    }

    func resolved(custom: String) -> String {
        switch self {
        case .doubleNewline: return "\n\n"
        case .newline:       return "\n"
        case .space:         return " "
        case .comma:         return ", "
        case .semicolon:     return "; "
        case .tab:           return "\t"
        case .custom:
            // Allow "\n" / "\t" escapes inside the user-provided string so the
            // text-field UI can express invisible separators.
            return custom
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
        }
    }
}

enum ImageMergeDirection: String, Codable, CaseIterable, Identifiable {
    case vertical
    case horizontal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .vertical:   return "纵向拼接"
        case .horizontal: return "横向拼接"
        }
    }

    var icon: String {
        switch self {
        case .vertical:   return "rectangle.split.1x2"
        case .horizontal: return "rectangle.split.2x1"
        }
    }
}

enum ImageMergeBackground: String, Codable, CaseIterable, Identifiable {
    case transparent
    case white
    case black

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .transparent: return "透明"
        case .white:       return "白色"
        case .black:       return "黑色"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .transparent: return .clear
        case .white:       return .white
        case .black:       return .black
        }
    }
}

@MainActor
final class MergeSettingsStore: ObservableObject {
    static let shared = MergeSettingsStore()

    @Published var deleteOriginals: Bool { didSet { save() } }
    @Published var textSeparator: MergeSeparatorPreset { didSet { save() } }
    @Published var textCustomSeparator: String { didSet { save() } }
    @Published var fileSeparator: MergeSeparatorPreset { didSet { save() } }
    @Published var fileCustomSeparator: String { didSet { save() } }
    @Published var enableImageMerge: Bool { didSet { save() } }
    @Published var imageDirection: ImageMergeDirection { didSet { save() } }
    @Published var imageSpacing: Double { didSet { save() } }
    @Published var imageBackground: ImageMergeBackground { didSet { save() } }

    private let key = "mergeSettings.v1"
    private var loading = false

    private struct StoredState: Codable {
        var deleteOriginals: Bool = false
        var textSeparator: String = MergeSeparatorPreset.doubleNewline.rawValue
        var textCustomSeparator: String = ""
        var fileSeparator: String = MergeSeparatorPreset.newline.rawValue
        var fileCustomSeparator: String = ""
        var enableImageMerge: Bool = false
        var imageDirection: String = ImageMergeDirection.vertical.rawValue
        var imageSpacing: Double = 0
        var imageBackground: String = ImageMergeBackground.transparent.rawValue
    }

    private init() {
        let stored: StoredState = {
            if let data = UserDefaults.standard.data(forKey: "mergeSettings.v1"),
               let s = try? JSONDecoder().decode(StoredState.self, from: data) {
                return s
            }
            return StoredState()
        }()
        self.deleteOriginals = stored.deleteOriginals
        self.textSeparator = MergeSeparatorPreset(rawValue: stored.textSeparator) ?? .doubleNewline
        self.textCustomSeparator = stored.textCustomSeparator
        self.fileSeparator = MergeSeparatorPreset(rawValue: stored.fileSeparator) ?? .newline
        self.fileCustomSeparator = stored.fileCustomSeparator
        self.enableImageMerge = stored.enableImageMerge
        self.imageDirection = ImageMergeDirection(rawValue: stored.imageDirection) ?? .vertical
        self.imageSpacing = stored.imageSpacing
        self.imageBackground = ImageMergeBackground(rawValue: stored.imageBackground) ?? .transparent
    }

    private func save() {
        guard !loading else { return }
        let state = StoredState(
            deleteOriginals: deleteOriginals,
            textSeparator: textSeparator.rawValue,
            textCustomSeparator: textCustomSeparator,
            fileSeparator: fileSeparator.rawValue,
            fileCustomSeparator: fileCustomSeparator,
            enableImageMerge: enableImageMerge,
            imageDirection: imageDirection.rawValue,
            imageSpacing: imageSpacing,
            imageBackground: imageBackground.rawValue
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func resolvedTextSeparator() -> String {
        textSeparator.resolved(custom: textCustomSeparator)
    }

    func resolvedFileSeparator() -> String {
        fileSeparator.resolved(custom: fileCustomSeparator)
    }
}
