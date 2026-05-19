import SwiftUI
import AppKit

struct FullDiskAccessOnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.appAccent, .appAccent.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .shadow(color: .appAccent.opacity(0.3), radius: 6, y: 2)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L("onboarding.title"))
                        .font(.system(size: 16, weight: .bold))
                    Text(L("onboarding.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle().fill(.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                .help(L("common.close"))
            }

            Text(L("onboarding.body"))
                .font(.system(size: 12.5))
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            steps

            HStack(spacing: 10) {
                Button {
                    Self.openFullDiskAccessPane()
                    onDismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(L("onboarding.openPrefs"))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appAccent)
                    )
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text(L("onboarding.later"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.secondary.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(20)
        .frame(width: 460, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator.opacity(0.55), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, y: 10)
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 6) {
            stepRow(index: 1, text: L("onboarding.step1"))
            stepRow(index: 2, text: L("onboarding.step2"))
            stepRow(index: 3, text: L("onboarding.step3"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.secondary.opacity(0.10))
        )
    }

    private func stepRow(index: Int, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(index)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(Color.appAccent))
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(.primary.opacity(0.85))
        }
    }

    static func openFullDiskAccessPane() {
        // Probe an FDA-gated file first. macOS only adds an app to the Full
        // Disk Access list after it has actually attempted to read a protected
        // location; without this attempt the pane opens but the app isn't in
        // the list, forcing the user to click "+" and locate it themselves.
        // The read is expected to fail when permission is missing — we only
        // need the access attempt itself to register the app with TCC.
        let probe = URL(fileURLWithPath: "/Library/Application Support/com.apple.TCC/TCC.db")
        _ = try? Data(contentsOf: probe)

        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
