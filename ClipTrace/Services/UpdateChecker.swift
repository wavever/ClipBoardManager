import Foundation
import Observation

/// Polls the public GitHub Releases API for the latest published release of
/// the project repo and compares its tag against the bundle's
/// `CFBundleShortVersionString`. The app is distributed exclusively through
/// GitHub Releases, so this is the canonical source of truth for "is there a
/// newer build available".
///
/// Tags are expected to follow `vX.Y.Z` (the leading `v` is optional). Pre-1.0
/// suffixes like `-beta`/`-rc.1` are tolerated but only the numeric core
/// participates in the comparison.
@Observable
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    enum Phase: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String, url: URL, notes: String)
        case error(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var lastChecked: Date?

    private var inflight: Task<Void, Never>?

    private static let endpoint = URL(string: "https://api.github.com/repos/wavever/ClipTrace/releases/latest")!

    private init() {}

    var currentVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
    }

    func check() {
        guard inflight == nil else { return }
        phase = .checking
        inflight = Task { [weak self] in
            guard let self else { return }
            defer { self.inflight = nil }
            do {
                let release = try await Self.fetchLatest()
                let latest = Self.normalize(release.tagName)
                self.lastChecked = Date()
                if Self.compareSemver(latest, self.currentVersion) == .orderedDescending {
                    self.phase = .available(
                        version: latest,
                        url: release.htmlURL,
                        notes: release.body.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    self.phase = .upToDate
                }
            } catch {
                self.phase = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    private static func fetchLatest() async throws -> Release {
        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("ClipTrace-macOS", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(http.statusCode == 404 ? .fileDoesNotExist : .badServerResponse)
        }
        return try JSONDecoder().decode(Release.self, from: data)
    }

    private struct Release: Decodable {
        let tagName: String
        let htmlURL: URL
        let body: String

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case body
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            tagName = try c.decode(String.self, forKey: .tagName)
            htmlURL = try c.decode(URL.self, forKey: .htmlURL)
            body = (try? c.decode(String.self, forKey: .body)) ?? ""
        }
    }

    private static func normalize(_ tag: String) -> String {
        var s = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("v") || s.hasPrefix("V") { s.removeFirst() }
        return s
    }

    static func compareSemver(_ lhs: String, _ rhs: String) -> ComparisonResult {
        func parts(_ s: String) -> [Int] {
            let core = s.split(separator: "-").first.map(String.init) ?? s
            return core.split(separator: ".").map { Int($0) ?? 0 }
        }
        let l = parts(lhs)
        let r = parts(rhs)
        let n = max(l.count, r.count)
        for i in 0..<n {
            let a = i < l.count ? l[i] : 0
            let b = i < r.count ? r[i] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }
}
