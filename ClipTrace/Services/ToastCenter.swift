import SwiftUI

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let systemImage: String
    let tint: Color
}

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published var current: Toast?

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(
        _ message: String,
        systemImage: String = "checkmark.circle.fill",
        tint: Color = .green,
        duration: TimeInterval = 2.2
    ) {
        dismissTask?.cancel()
        let toast = Toast(message: message, systemImage: systemImage, tint: tint)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            current = toast
        }
        let id = toast.id
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.current?.id == id else { return }
                withAnimation(.easeIn(duration: 0.2)) {
                    self.current = nil
                }
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeIn(duration: 0.18)) {
            current = nil
        }
    }
}
