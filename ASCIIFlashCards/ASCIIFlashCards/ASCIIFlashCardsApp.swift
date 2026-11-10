// xcode: set sdk=iOS

import SwiftUI
import SwiftData

// MARK: - Main App Entry
@main
struct ASCIIFlashCardsApp: App {
    let container: ModelContainer
    @StateObject private var deckStore: DeckStore

    init() {
        do {
            let schema = Schema([
                Deck.self,
                FlashCard.self,
                StudyStatsRecord.self
            ])
            let isTest = CommandLine.arguments.contains("-UITestMode")
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isTest)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            let store = DeckStore(modelContainer: container)
            if CommandLine.arguments.contains("-UITest_Empty") {
                store.decks = []
            }
            self._deckStore = StateObject(wrappedValue: store)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(deckStore)
                .modelContainer(container)
        }
    }
}
