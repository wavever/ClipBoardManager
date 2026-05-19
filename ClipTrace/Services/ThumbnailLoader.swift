import AppKit
import QuickLookThumbnailing

@MainActor
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let cache = NSCache<NSString, NSImage>()
    private var inflight: [String: Task<NSImage?, Never>] = [:]

    private init() {
        cache.countLimit = 200
    }

    private func cacheKey(for item: ClipboardItem, size: CGSize) -> String {
        "\(item.id.uuidString)_\(Int(size.width))x\(Int(size.height))"
    }

    func cached(for item: ClipboardItem, size: CGSize) -> NSImage? {
        cache.object(forKey: cacheKey(for: item, size: size) as NSString)
    }

    func thumbnail(for item: ClipboardItem, size: CGSize) async -> NSImage? {
        let key = cacheKey(for: item, size: size)
        if let img = cache.object(forKey: key as NSString) { return img }

        if let task = inflight[key] {
            return await task.value
        }

        let task = Task<NSImage?, Never> { [weak self] in
            let image = await Self.generate(for: item, size: size)
            if let image, let self {
                self.cache.setObject(image, forKey: key as NSString)
            }
            self?.inflight[key] = nil
            return image
        }
        inflight[key] = task
        return await task.value
    }

    private static func generate(for item: ClipboardItem, size: CGSize) async -> NSImage? {
        if let data = item.imageData, let img = NSImage(data: data) {
            return resize(img, to: size)
        }

        guard let url = item.resolvedFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let request = QLThumbnailGenerator.Request(
            fileAt: url,
            size: size,
            scale: scale,
            representationTypes: .all
        )

        return await withCheckedContinuation { continuation in
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                if let rep {
                    continuation.resume(returning: rep.nsImage)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private static func resize(_ image: NSImage, to size: CGSize) -> NSImage {
        let result = NSImage(size: size)
        result.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        let aspect = min(size.width / image.size.width, size.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * aspect, height: image.size.height * aspect)
        let drawOrigin = CGPoint(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2)
        image.draw(in: NSRect(origin: drawOrigin, size: drawSize),
                   from: .zero,
                   operation: .copy,
                   fraction: 1.0)
        _ = rect
        result.unlockFocus()
        return result
    }
}
