import Foundation
import SwiftUI

struct AppFilterEntry: Codable, Identifiable, Hashable {
    var id: String { bundleId }
    let bundleId: String
    let name: String
}

struct TextFilterRule: Codable, Identifiable, Hashable {
    enum Mode: String, Codable, CaseIterable, Identifiable {
        case contains
        case excludes

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .contains: return "包含文本"
            case .excludes: return "不包含文本"
            }
        }
    }

    var id: UUID = UUID()
    var mode: Mode
    var text: String
}

@MainActor
final class FilterSettingsStore: ObservableObject {
    static let shared = FilterSettingsStore()

    @Published var excludedApps: [AppFilterEntry] = [] { didSet { save() } }
    @Published var excludedTypes: Set<ClipboardItemType> = [] { didSet { save() } }
    @Published var textFilters: [TextFilterRule] = [] { didSet { save() } }
    @Published var stripURLTracking: Bool = true { didSet { save() } }
    /// Per-type retention in days. 0 (or missing) means "keep forever".
    @Published var retentionByType: [String: Int] = [:] { didSet { save() } }

    private let key = "filterSettings.v1"
    private var loading = false

    private init() {
        load()
    }

    private struct StoredState: Codable {
        var excludedApps: [AppFilterEntry] = []
        var excludedTypes: [String] = []
        var textFilters: [TextFilterRule] = []
        var stripURLTracking: Bool? = true
        var retentionByType: [String: Int]? = nil
    }

    private func load() {
        loading = true
        defer { loading = false }
        guard let data = UserDefaults.standard.data(forKey: key),
              let state = try? JSONDecoder().decode(StoredState.self, from: data) else {
            return
        }
        excludedApps = state.excludedApps
        excludedTypes = Set(state.excludedTypes.compactMap { ClipboardItemType(rawValue: $0) })
        textFilters = state.textFilters
        stripURLTracking = state.stripURLTracking ?? true
        retentionByType = state.retentionByType ?? [:]
    }

    private func save() {
        guard !loading else { return }
        let state = StoredState(
            excludedApps: excludedApps,
            excludedTypes: excludedTypes.map { $0.rawValue }.sorted(),
            textFilters: textFilters,
            stripURLTracking: stripURLTracking,
            retentionByType: retentionByType.isEmpty ? nil : retentionByType
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Retention window in days for `type`. `0` means "keep forever".
    func retentionDays(for type: ClipboardItemType) -> Int {
        retentionByType[type.rawValue] ?? 0
    }

    func setRetentionDays(_ days: Int, for type: ClipboardItemType) {
        if days <= 0 {
            retentionByType.removeValue(forKey: type.rawValue)
        } else {
            retentionByType[type.rawValue] = days
        }
    }

    func shouldExclude(type: ClipboardItemType, content: String, sourceBundleId: String) -> Bool {
        if !sourceBundleId.isEmpty,
           excludedApps.contains(where: { $0.bundleId == sourceBundleId }) {
            return true
        }
        if excludedTypes.contains(type) {
            return true
        }
        for rule in textFilters where !rule.text.isEmpty {
            switch rule.mode {
            case .contains:
                if content.localizedCaseInsensitiveContains(rule.text) { return true }
            case .excludes:
                if !content.localizedCaseInsensitiveContains(rule.text) { return true }
            }
        }
        return false
    }
}
