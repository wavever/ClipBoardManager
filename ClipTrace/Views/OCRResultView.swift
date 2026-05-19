import SwiftUI
import AppKit

/// Modal shown after the user hits the OCR button on an image row. Kicks off
/// Vision-based recognition on appear and always renders the result body — an
/// empty result becomes a "no text found" placeholder rather than a silent
/// dismissal, because users explicitly asked for that feedback. The sheet has
/// no cancel affordance: only the trailing Close button can dismiss it.
@MainActor
struct OCRResultView: View {
    let item: ClipboardItem
    let onClose: () -> Void

    @State private var recognizedText: String = ""
    @State private var isRecognizing: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(width: 520, height: 420)
        .task {
            recognizedText = await OCRService.shared.recognize(item: item)
            isRecognizing = false
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "text.below.photo")
                .foregroundStyle(Color.appAccent)
            Text(L("ocr.title"))
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if isRecognizing {
            VStack(spacing: 10) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                Text(L("ocr.recognizing"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if recognizedText.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "text.badge.xmark")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.secondary)
                Text(L("ocr.empty"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                Text(recognizedText)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(14)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if !isRecognizing, !recognizedText.isEmpty {
                Button {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(recognizedText, forType: .string)
                    ClipboardMonitor.markInternalWrite()
                    ToastCenter.shared.show(
                        L("common.copied"),
                        systemImage: "doc.on.doc",
                        tint: .appAccent
                    )
                } label: {
                    Label(L("ocr.copyAll"), systemImage: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            Spacer()
            Button(action: onClose) {
                Text(L("common.close"))
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appAccent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
