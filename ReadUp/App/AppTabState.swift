import Foundation

final class AppTabState: ObservableObject {
    @Published var selectedTab: Int = 0

    func goToSearchTab() {
        selectedTab = 2
    }
}
