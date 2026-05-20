import Foundation
import Observation

/// Polls the public GitHub Releases Atom feed for the latest published release
/// of the project repo and compares its tag against the bundle's
/// `CFBundleShortVersionString`. The app is distributed exclusively through
/// GitHub Releases, so this is the canonical source of truth for "is there a
/// newer build available".
///
/// We deliberately use the `releases.atom` page (a public HTML feed) instead
/// of `api.github.com/.../releases/latest`. The API endpoint is gated by a
/// 60-request-per-hour-per-IP rate limit for unauthenticated callers; users
/// sharing a NAT or behind corporate egress hit it constantly and the error
/// surfaces as a confusing "NSURLErrorDomain -1011". The atom feed serves the
/// same data without that limit.
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

    private static let endpoint = URL(string: "https://github.com/wavever/ClipTrace/releases.atom")!

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
                let latest = Self.normalize(release.tag)
                self.lastChecked = Date()
                if Self.compareSemver(latest, self.currentVersion) == .orderedDescending {
                    self.phase = .available(
                        version: latest,
                        url: release.htmlURL,
                        notes: release.notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    self.phase = .upToDate
                }
            } catch {
                self.phase = .error((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
            }
        }
    }

    /// Surface-level error with a human-readable message. Lets the UI show
    /// something more actionable than Apple's cryptic `-1011` from
    /// `URLError(.badServerResponse)`.
    struct CheckError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Polite UA string so GitHub can attribute traffic if anything ever needs
    /// triaging. The atom feed doesn't require it but the convention costs us
    /// nothing.
    private static var userAgent: String {
        let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.0.0"
        return "ClipTrace/\(version) (macOS; +https://github.com/wavever/ClipTrace)"
    }

    fileprivate struct Release {
        let tag: String
        let htmlURL: URL
        let notes: String
    }

    private static func fetchLatest() async throws -> Release {
        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let status = http.statusCode
            let reason: String
            switch status {
            case 404:
                reason = "No releases found (HTTP 404)."
            case 500...599:
                reason = "GitHub server error (HTTP \(status)). Please try again later."
            default:
                reason = "Unexpected response from GitHub (HTTP \(status))."
            }
            throw CheckError(message: reason)
        }
        guard let release = AtomFeedParser.parseFirstEntry(data: data) else {
            throw CheckError(message: "Could not parse releases feed.")
        }
        return release
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

/// Tiny XMLParser-based extractor that returns the first `<entry>` of a GitHub
/// Releases Atom feed. We only need three fields — `<title>` (tag),
/// `<link rel="alternate" href="…">` (release page URL), and `<content
/// type="html">` (HTML notes) — so a full DOM library would be overkill.
///
/// `<content>` is HTML-escaped inside the XML; after `foundCharacters`
/// decodes the entities we still get an HTML fragment, which `stripHTML`
/// reduces to plain text suitable for a release-notes blurb.
private final class AtomFeedParser: NSObject, XMLParserDelegate {
    static func parseFirstEntry(data: Data) -> UpdateChecker.Release? {
        let delegate = AtomFeedParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        guard let tag = delegate.title, let url = delegate.htmlURL else { return nil }
        return UpdateChecker.Release(tag: tag, htmlURL: url, notes: delegate.notesText)
    }

    private var inEntry = false
    private var entryFinished = false
    private var currentElement = ""
    private var buffer = ""

    private var title: String?
    private var htmlURL: URL?
    private var notesText: String = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if entryFinished { return }
        if elementName == "entry" {
            inEntry = true
            return
        }
        guard inEntry else { return }
        currentElement = elementName
        buffer = ""
        if elementName == "link",
           attributeDict["rel"] == "alternate",
           let href = attributeDict["href"],
           let url = URL(string: href) {
            htmlURL = url
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if entryFinished || !inEntry { return }
        buffer += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if entryFinished { return }
        if elementName == "entry" {
            // Stop after the most recent entry — the rest are older releases.
            entryFinished = true
            parser.abortParsing()
            return
        }
        guard inEntry else { return }
        switch elementName {
        case "title":
            if title == nil {
                title = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "content":
            notesText = Self.stripHTML(buffer)
        default:
            break
        }
        currentElement = ""
        buffer = ""
    }

    /// Reduce GitHub's release-notes HTML to plain text. We deliberately keep
    /// this small (no NSAttributedString HTML import — that's slow and main-
    /// actor-bound): block-level tags become newlines, list items get a
    /// leading dash, everything else is stripped, and a handful of named
    /// entities are decoded. Quality is good enough for a short notes blurb.
    private static func stripHTML(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "</li>", with: "\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<li[^>]*>", with: "- ", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&#x27;", with: "'", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        // Decode `&amp;` last so we don't double-decode entities that contain `&`.
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
