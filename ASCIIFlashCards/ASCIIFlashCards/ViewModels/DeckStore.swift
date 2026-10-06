import SwiftUI
import Combine

// MARK: - DeckStore (Main Data Manager)
class DeckStore: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var studyStats: StudyStats = StudyStats()

    private let saveKey = "ascii_flashcards_decks"
    private let statsKey = "ascii_flashcards_stats"

    init() {
        loadDecks()
        loadStats()
        if decks.isEmpty {
            decks = [Deck.sampleDeck, Deck.japaneseVocabDeck]
            saveDecks()
        }
    }

    // MARK: - CRUD Operations
    func addDeck(_ deck: Deck) {
        decks.append(deck)
        saveDecks()
    }

    func deleteDeck(at offsets: IndexSet) {
        decks.remove(atOffsets: offsets)
        saveDecks()
    }

    func deleteDeck(byId id: UUID) {
        decks.removeAll { $0.id == id }
        saveDecks()
    }

    func updateDeck(_ deck: Deck) {
        if let idx = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[idx] = deck
            saveDecks()
        }
    }

    func addCard(_ card: FlashCard, toDeckId deckId: UUID) {
        if let idx = decks.firstIndex(where: { $0.id == deckId }) {
            decks[idx].cards.append(card)
            saveDecks()
        }
    }

    func updateCard(_ card: FlashCard, inDeckId deckId: UUID) {
        if let deckIdx = decks.firstIndex(where: { $0.id == deckId }),
           let cardIdx = decks[deckIdx].cards.firstIndex(where: { $0.id == card.id }) {
            decks[deckIdx].cards[cardIdx] = card
            saveDecks()
        }
    }

    func deleteCard(cardId: UUID, fromDeckId deckId: UUID) {
        if let deckIdx = decks.firstIndex(where: { $0.id == deckId }) {
            decks[deckIdx].cards.removeAll { $0.id == cardId }
            saveDecks()
        }
    }

    func recordReview(cardId: UUID, deckId: UUID, correct: Bool) {
        if let deckIdx = decks.firstIndex(where: { $0.id == deckId }),
           let cardIdx = decks[deckIdx].cards.firstIndex(where: { $0.id == cardId }) {
            var card = decks[deckIdx].cards[cardIdx]
            card.reviewCount += 1
            card.lastReviewed = Date()
            if correct {
                card.masteryLevel = min(5, card.masteryLevel + 1)
                studyStats.correctCount += 1
            } else {
                card.masteryLevel = max(0, card.masteryLevel - 1)
                studyStats.incorrectCount += 1
            }
            decks[deckIdx].cards[cardIdx] = card
            studyStats.totalReviews += 1
            studyStats.lastStudied = Date()
            saveDecks()
            saveStats()
        }
    }

    // MARK: - Persistence
    private func saveDecks() {
        if let encoded = try? JSONEncoder().encode(decks) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    private func loadDecks() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Deck].self, from: data) {
            decks = decoded
        }
    }

    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(studyStats) {
            UserDefaults.standard.set(encoded, forKey: statsKey)
        }
    }

    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(StudyStats.self, from: data) {
            studyStats = decoded
        }
    }

    // MARK: - Computed Stats
    var totalCards: Int {
        decks.reduce(0) { $0 + $1.cards.count }
    }

    var totalMastered: Int {
        decks.reduce(0) { $0 + $1.masteredCount }
    }

    var overallProgress: Double {
        guard totalCards > 0 else { return 0 }
        return Double(totalMastered) / Double(totalCards) * 100
    }
}

// MARK: - StudyStats
struct StudyStats: Codable {
    var totalReviews: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var currentStreak: Int = 0
    var lastStudied: Date? = nil

    var accuracy: Double {
        guard totalReviews > 0 else { return 0 }
        return Double(correctCount) / Double(totalReviews) * 100
    }

    var accuracyBar: String {
        let filled = Int(accuracy / 10)
        let empty = 10 - filled
        return "[" + String(repeating: "#", count: filled) + String(repeating: "-", count: empty) + "]"
    }
}
