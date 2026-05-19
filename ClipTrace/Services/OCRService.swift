import Foundation
import Vision
import AppKit

/// Offline OCR for clipboard images using the Vision framework. Recognition
/// runs on a detached background task so the calling view can `await` without
/// blocking the main actor, and the request is configured for the languages
/// our users are most likely to clip: Chinese (Simplified + Traditional)
/// and English.
final class OCRService {
    static let shared = OCRService()

    private init() {}

    /// Run OCR against an image-typed `ClipboardItem`. Returns the recognized
    /// text joined by newlines, or an empty string when no text was found or
    /// the image cannot be decoded.
    func recognize(item: ClipboardItem) async -> String {
        if let data = item.imageData {
            return await recognize(imageData: data)
        }
        if let url = item.resolvedFileURL,
           let data = try? Data(contentsOf: url) {
            return await recognize(imageData: data)
        }
        return ""
    }

    func recognize(imageData: Data) async -> String {
        await Task.detached(priority: .userInitiated) { () -> String in
            guard let image = NSImage(data: imageData),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return ""
            }
            return Self.performOCR(cgImage: cgImage)
        }.value
    }

    private static func performOCR(cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        // Chinese text recognition only landed in macOS 13. On older OSes we
        // fall back to whatever Apple supports (mostly Latin scripts).
        if #available(macOS 13.0, *) {
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return ""
        }
        guard let observations = request.results else { return "" }
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
