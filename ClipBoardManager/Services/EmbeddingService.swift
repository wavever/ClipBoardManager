import Foundation
import NaturalLanguage

/// Wraps Apple's built-in sentence embeddings (NLEmbedding.sentenceEmbedding)
/// for cheap local semantic similarity. No download required — vectors are
/// shipped with the OS. Cross-language vectors are NOT comparable, so each
/// item stores the language it was embedded in and queries only score against
/// items in the same language.
///
/// **Thread safety**: CoreNLP is not thread-safe. All NLEmbedding work is
/// funneled through a single serial `DispatchQueue` to prevent heap
/// corruption crashes.
final class EmbeddingService: @unchecked Sendable {
    static let shared = EmbeddingService()

    private let queue = DispatchQueue(label: "com.clipboard.embedding", qos: .utility)

    private init() {}

    struct Vector {
        let data: Data        // packed Float32
        let language: String  // NLLanguage.rawValue
        let dimension: Int
    }

    /// Compute an embedding for the given text. Thread-safe; the work runs on
    /// a dedicated serial queue. Returns nil for empty text or if no model is
    /// available for the detected language.
    func embed(_ text: String) -> Vector? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let snippet = String(trimmed.prefix(2_000))
        return queue.sync { _embed(snippet) }
    }

    /// Async variant for use in async contexts without blocking the caller.
    func embedAsync(_ text: String) async -> Vector? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let snippet = String(trimmed.prefix(2_000))
        return await withCheckedContinuation { cont in
            queue.async {
                cont.resume(returning: self._embed(snippet))
            }
        }
    }

    private func _embed(_ snippet: String) -> Vector? {
        let rawLang = detectLanguage(snippet)
        let lang = normalizeLanguage(rawLang)
        guard let model = model(for: rawLang) else { return nil }
        guard let vec = model.vector(for: snippet) else { return nil }

        var floats = vec.map { Float($0) }
        let data = floats.withUnsafeMutableBufferPointer { buf -> Data in
            Data(buffer: buf)
        }
        return Vector(data: data, language: lang, dimension: floats.count)
    }

    /// Collapse fine-grained NLLanguage codes into two families:
    ///  `zh` (any Chinese variant) and `en` (everything else).
    ///  This avoids mismatches when NLLanguageRecognizer returns `nl`, `da`,
    ///  `id` etc. for short Latin-script snippets.
    func normalizeLanguage(_ lang: NLLanguage) -> String {
        let raw = lang.rawValue
        if raw.hasPrefix("zh") { return "zh" }
        return "en"
    }

    /// Cosine similarity between two packed Float32 vectors. Returns 0 when
    /// either side is invalid or zero-magnitude.
    func cosineSimilarity(_ lhs: Data, _ rhs: Data) -> Float {
        guard lhs.count == rhs.count, lhs.count >= MemoryLayout<Float>.size else { return 0 }
        return lhs.withUnsafeBytes { lhsRaw -> Float in
            rhs.withUnsafeBytes { rhsRaw -> Float in
                let a = lhsRaw.bindMemory(to: Float.self)
                let b = rhsRaw.bindMemory(to: Float.self)
                let n = min(a.count, b.count)
                var dot: Float = 0
                var na: Float = 0
                var nb: Float = 0
                for i in 0..<n {
                    let x = a[i]
                    let y = b[i]
                    dot += x * y
                    na += x * x
                    nb += y * y
                }
                guard na > 0, nb > 0 else { return 0 }
                return dot / (sqrt(na) * sqrt(nb))
            }
        }
    }

    func detectLanguage(_ text: String) -> NLLanguage {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage ?? .english
    }

    private var _cachedModel: NLEmbedding?

    /// Always returns the English sentence embedding model. Apple's English
    /// sentence model handles multilingual text (including CJK) reasonably
    /// well, and using a single model avoids dimension mismatches caused by
    /// inconsistent language detection on short clipboard snippets.
    private func model(for language: NLLanguage) -> NLEmbedding? {
        if let cached = _cachedModel { return cached }
        let model = NLEmbedding.sentenceEmbedding(for: .english)
        _cachedModel = model
        return model
    }
}
