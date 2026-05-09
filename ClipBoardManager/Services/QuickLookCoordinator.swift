import AppKit
import QuickLookUI

final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookCoordinator()

    private var urls: [URL] = []
    private var currentIndex: Int = 0

    func preview(url: URL) {
        preview(urls: [url])
    }

    func preview(urls: [URL], startingAt index: Int = 0) {
        guard !urls.isEmpty else { return }
        self.urls = urls
        self.currentIndex = max(0, min(index, urls.count - 1))

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.currentPreviewItemIndex = currentIndex
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: QLPreviewPanelDataSource
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }

    // MARK: QLPreviewPanelDelegate
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        if event.type == .keyDown {
            panel.keyDown(with: event)
            return true
        }
        return false
    }
}
