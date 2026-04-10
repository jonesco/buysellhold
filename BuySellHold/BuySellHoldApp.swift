import SwiftUI
import SwiftData

@main
struct BuySellHoldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WatchlistItem.self, UserPreferences.self])
    }
}
