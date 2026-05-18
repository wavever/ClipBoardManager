import AppKit
import SwiftUI

@MainActor
final class DynamicIslandController: NSObject {
    static let shared = DynamicIslandController()

    private var panel: NSPanel?
    private var hostingController: NSHostingController<DynamicIslandView>?
    private var state: DynamicIslandState = .idle
    private var toastTimer: Timer?

    private override init() { super.init() }

    /// True when the user has enabled the feature in Settings.
    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "dynamicIslandEnabled")
    }

    /// Called on app launch and whenever the setting toggles.
    func setEnabled(_ enabled: Bool) {
        if enabled {
            show()
        } else {
            hide()
        }
    }

    /// Call after a new clipboard item has been recorded. Briefly expands the
    /// pill into a toast that shows the item's type + preview, then collapses.
    func flash(itemIcon: String, preview: String) {
        guard panel != nil else { return }
        toastTimer?.invalidate()
        applyState(.toast(itemTypeIcon: itemIcon, preview: preview))
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.applyState(.idle)
            }
        }
    }

    // MARK: - Panel lifecycle

    private func show() {
        guard panel == nil else { return }

        let initialState: DynamicIslandState = .idle
        let view = DynamicIslandView(state: initialState) { [weak self] in
            self?.handleClick()
        }
        let hosting = NSHostingController(rootView: view)
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = .clear

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialState.size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        // statusBar level keeps the pill above ordinary windows but below
        // system overlays; we live alongside the menu bar.
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        // Travel to all spaces (including fullscreen apps) so the pill is
        // always reachable without switching desktops.
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.contentViewController = hosting

        self.panel = panel
        self.hostingController = hosting
        self.state = initialState

        positionPanel(for: initialState)
        panel.orderFrontRegardless()
    }

    private func hide() {
        toastTimer?.invalidate()
        toastTimer = nil
        panel?.orderOut(nil)
        panel = nil
        hostingController = nil
        state = .idle
    }

    private func applyState(_ newState: DynamicIslandState) {
        guard newState != state else { return }
        state = newState
        hostingController?.rootView = DynamicIslandView(state: newState) { [weak self] in
            self?.handleClick()
        }
        positionPanel(for: newState)
    }

    /// Anchor the panel to the top-center of the main screen, just below the
    /// menu bar. On notched MacBooks this naturally lands directly beneath
    /// the notch.
    private func positionPanel(for state: DynamicIslandState) {
        guard let panel else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }

        let size = state.size
        let visible = screen.visibleFrame
        let originX = screen.frame.midX - size.width / 2
        let originY = visible.maxY - size.height - 4
        let frame = NSRect(x: originX, y: originY, width: size.width, height: size.height)
        panel.setFrame(frame, display: true, animate: true)
    }

    // MARK: - Click handling

    private func handleClick() {
        // Tapping the pill opens the same quick-paste list, anchored just
        // below the island so it visually drops down from the notch.
        let anchor: NSPoint
        if let panel {
            anchor = NSPoint(x: panel.frame.midX, y: panel.frame.minY - 4)
        } else {
            anchor = NSPoint(
                x: (NSScreen.main?.frame.midX ?? 0),
                y: (NSScreen.main?.visibleFrame.maxY ?? 0) - 36
            )
        }
        QuickPasteController.shared.show(anchor: anchor)
    }
}
