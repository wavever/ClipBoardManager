import SwiftUI
import AVKit
import AppKit

struct PreviewPopover: View {
    let item: ClipboardItem

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: item.itemType.icon)
                    .foregroundStyle(.secondary)
                Text(item.itemType.displayName)
                    .font(.headline)
                Spacer()
                Text(item.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 360, idealWidth: 460, minHeight: 240, idealHeight: 320)
    }

    @ViewBuilder
    private var content: some View {
        switch item.itemType {
        case .text, .url:
            VStack(spacing: 8) {
                ScrollView {
                    Text(item.content)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                decodeCard(for: item.content)
            }
        case .rtf:
            VStack(spacing: 8) {
                ScrollView {
                    Text(item.content)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                decodeCard(for: item.content)
            }
        case .image:
            if let img = imageToShow() {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                ContentUnavailableView(L("preview.cannotImage"), systemImage: "photo.badge.exclamationmark")
            }
        case .video:
            if let url = item.resolvedFileURL, FileManager.default.fileExists(atPath: url.path) {
                VideoPlayer(player: AVPlayer(url: url))
                    .padding(8)
            } else {
                ContentUnavailableView(L("preview.cannotVideo"), systemImage: "video.badge.exclamationmark")
            }
        case .file:
            VStack(spacing: 12) {
                if let url = item.resolvedFileURL {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .frame(width: 96, height: 96)
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .semibold))
                    Text(url.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text(item.content)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private func imageToShow() -> NSImage? {
        if let data = item.imageData, let img = NSImage(data: data) { return img }
        if let url = item.resolvedFileURL, let img = NSImage(contentsOf: url) { return img }
        return nil
    }

    // MARK: - Decode Card

    @ViewBuilder
    private func decodeCard(for raw: String) -> some View {
        let epoch = PreviewPopover.epochInterpretation(of: raw)
        let base64 = PreviewPopover.base64Decoded(of: raw)
        let json = PreviewPopover.prettyJSON(of: raw)

        if epoch != nil || base64 != nil || json != nil {
            VStack(spacing: 8) {
                if let epoch = epoch {
                    detectionCard(icon: "clock", title: L("preview.detection.timestamp")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("preview.utcFormat", epoch.utc))
                            Text(L("preview.localFormat", epoch.local))
                        }
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if let decoded = base64 {
                    detectionCard(icon: "lock.shield", title: L("preview.detection.base64")) {
                        Text(decoded)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if let pretty = json {
                    detectionCard(icon: "curlybraces", title: L("preview.detection.json")) {
                        ScrollView {
                            Text(pretty)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 160)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func detectionCard<Body: View>(
        icon: String,
        title: String,
        @ViewBuilder body: () -> Body
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            body()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.5)
        )
    }

    // MARK: - Detectors

    private static func epochInterpretation(of s: String) -> (utc: String, local: String)? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.count == 10 || trimmed.count == 13 else { return nil }
        guard trimmed.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        guard let value = Double(trimmed) else { return nil }

        let seconds: TimeInterval = trimmed.count == 13 ? value / 1000.0 : value

        // 1990-01-01 .. 2100-12-31 23:59:59 UTC
        let lower: TimeInterval = 631_152_000     // 1990-01-01
        let upper: TimeInterval = 4_133_980_799   // 2100-12-31
        guard seconds >= lower && seconds <= upper else { return nil }

        let date = Date(timeIntervalSince1970: seconds)

        let utcFormatter = DateFormatter()
        utcFormatter.locale = Locale(identifier: "en_US_POSIX")
        utcFormatter.timeZone = TimeZone(identifier: "UTC")
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'UTC'"

        let localFormatter = DateFormatter()
        localFormatter.locale = Locale(identifier: "en_US_POSIX")
        localFormatter.timeZone = TimeZone.current
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"

        return (utc: utcFormatter.string(from: date), local: localFormatter.string(from: date))
    }

    private static func base64Decoded(of s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 12 else { return nil }
        guard trimmed.count % 4 == 0 else { return nil }

        // Charset check.
        let allowed: Set<Character> = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        guard trimmed.allSatisfy({ allowed.contains($0) }) else { return nil }

        // Reduce false positives: require at least one non-letter character.
        let hasNonLetter = trimmed.contains { ch in
            ch == "+" || ch == "/" || ch == "=" || ch.isNumber
        }
        guard hasNonLetter else { return nil }

        guard let data = Data(base64Encoded: trimmed) else { return nil }
        guard let decoded = String(data: data, encoding: .utf8) else { return nil }

        // Require at least 1 non-control character.
        let hasPrintable = decoded.unicodeScalars.contains { scalar in
            !CharacterSet.controlCharacters.contains(scalar)
        }
        guard hasPrintable else { return nil }

        if decoded.count > 280 {
            let idx = decoded.index(decoded.startIndex, offsetBy: 280)
            return String(decoded[..<idx]) + "…"
        }
        return decoded
    }

    private static func prettyJSON(of s: String) -> String? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "{" || first == "[" else { return nil }
        guard let data = trimmed.data(using: .utf8) else { return nil }
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let pretty = try? JSONSerialization.data(
            withJSONObject: obj,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return nil }
        guard var str = String(data: pretty, encoding: .utf8) else { return nil }

        if str.count > 600 {
            let idx = str.index(str.startIndex, offsetBy: 600)
            str = String(str[..<idx]) + "\n…"
        }
        return str
    }
}
