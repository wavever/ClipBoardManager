import Foundation
import Sparkle

/// SwiftUI-friendly wrapper around Sparkle's `SPUStandardUpdaterController`.
///
/// Sparkle handles the entire update lifecycle — appcast fetch, EdDSA signature
/// verification, DMG download, app replacement, and relaunch — and ships a
/// polished standard UI for each step. We just expose two things to the rest
/// of the app:
///
/// 1. `checkForUpdates()` — fire a user-initiated check; Sparkle takes over from there.
/// 2. `canCheck` — a `@Published` mirror of the updater's busy state so the UI
///    can disable the button while a check is already in flight.
///
/// `SPUStandardUpdaterController(startingUpdater: true, …)` boots the updater
/// on init, which also kicks off the configured background check schedule
/// (controlled by `SUEnableAutomaticChecks` / `SUScheduledCheckInterval` in
/// Info.plist). Keep the singleton alive for the app's lifetime so background
/// checks keep running even when the Settings window is closed.
@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()

    @Published private(set) var canCheck: Bool = true

    let controller: SPUStandardUpdaterController
    private var observation: NSKeyValueObservation?

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        observation = controller.updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] updater, _ in
            let value = updater.canCheckForUpdates
            Task { @MainActor in
                self?.canCheck = value
            }
        }
    }

    /// User-initiated update check. Sparkle drives the dialogs from here:
    /// "Checking…" → "Up to date" / "Update available" with release notes →
    /// "Downloading" → "Install and Relaunch".
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
