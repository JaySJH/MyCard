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
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            self._deckStore = StateObject(wrappedValue: DeckStore(modelContainer: container))
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
