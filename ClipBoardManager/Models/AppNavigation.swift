import SwiftUI

enum MainScreen: String {
    case list
    case settings
    case stats
}

@MainActor
final class AppNavigation: ObservableObject {
    static let shared = AppNavigation()

    @Published var screen: MainScreen = .list

    private init() {}

    func showSettings() { screen = .settings }
    func showList() { screen = .list }
    func showStats() { screen = .stats }
}
