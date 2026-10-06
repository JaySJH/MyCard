import SwiftUI

// MARK: - Main App Entry
@main
struct ASCIIFlashCardsApp: App {
    @StateObject private var deckStore = DeckStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deckStore)
                .preferredColorScheme(.dark)
        }
    }
}
