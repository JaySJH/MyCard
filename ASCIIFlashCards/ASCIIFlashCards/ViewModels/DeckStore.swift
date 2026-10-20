import SwiftUI
import Combine
import SwiftData

// MARK: - Legacy Data Structures for Migration
private struct LegacyDeck: Codable {
    let id: UUID
    let name: String
    let description: String?
    let cards: [LegacyCard]?
    let createdAt: Date?
    let colorTheme: DeckTheme?
}

private struct LegacyCard: Codable {
    let id: UUID
    let word: String
    let definition: String
    let example: String?
    let partOfSpeech: PartOfSpeech?
    let difficulty: Difficulty?
    let tags: [String]?
    let masteryLevel: Int?
    let reviewCount: Int?
    let lastReviewed: Date?
    let createdAt: Date?
}

// MARK: - DeckStore (Main Data Manager)
@MainActor
class DeckStore: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var studyStats: StudyStats = StudyStats()

    let modelContainer: ModelContainer
    var modelContext: ModelContext {
        modelContainer.mainContext
    }

    private let saveKey = "ascii_flashcards_decks"
    private let statsKey = "ascii_flashcards_stats"
    private let migrationKey = "ascii_flashcards_migrated_to_swiftdata"
    private let hasSeededKey = "ascii_flashcards_has_seeded_initial_data"

    init(modelContainer: ModelContainer? = nil) {
        if let container = modelContainer {
            self.modelContainer = container
        } else {
            do {
                let schema = Schema([
                    Deck.self,
                    FlashCard.self,
                    StudyStatsRecord.self
                ])
                let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                self.modelContainer = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
            }
        }

        migrateLegacyDataIfNeeded()
        fetchDecks()
        fetchStats()

        let hasSeeded = UserDefaults.standard.bool(forKey: hasSeededKey)
        if decks.isEmpty && !hasSeeded {
            seedInitialData()
        } else if !decks.isEmpty && !hasSeeded {
            UserDefaults.standard.set(true, forKey: hasSeededKey)
        }
    }

    // MARK: - Migration & Seeding
    private func migrateLegacyDataIfNeeded() {
        let hasMigrated = UserDefaults.standard.bool(forKey: migrationKey)
        guard !hasMigrated else { return }

        // 1. Check for legacy decks in UserDefaults
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let legacyDecks = try? JSONDecoder().decode([LegacyDeck].self, from: data),
           !legacyDecks.isEmpty {
            for legacyDeck in legacyDecks {
                let deck = Deck(
                    id: legacyDeck.id,
                    name: legacyDeck.name,
                    description: legacyDeck.description ?? "",
                    createdAt: legacyDeck.createdAt ?? Date(),
                    colorTheme: legacyDeck.colorTheme ?? .green
                )
                modelContext.insert(deck)

                if let cards = legacyDeck.cards {
                    for legacyCard in cards {
                        let card = FlashCard(
                            id: legacyCard.id,
                            word: legacyCard.word,
                            definition: legacyCard.definition,
                            example: legacyCard.example ?? "",
                            partOfSpeech: legacyCard.partOfSpeech ?? .noun,
                            difficulty: legacyCard.difficulty ?? .medium,
                            tags: legacyCard.tags ?? [],
                            masteryLevel: legacyCard.masteryLevel ?? 0,
                            reviewCount: legacyCard.reviewCount ?? 0,
                            lastReviewed: legacyCard.lastReviewed,
                            createdAt: legacyCard.createdAt ?? Date(),
                            deck: deck
                        )
                        deck.cards.append(card)
                        modelContext.insert(card)
                    }
                }
            }
            UserDefaults.standard.removeObject(forKey: saveKey)
        }

        // 2. Check for legacy stats in UserDefaults
        if let data = UserDefaults.standard.data(forKey: statsKey),
           let legacyStats = try? JSONDecoder().decode(StudyStats.self, from: data) {
            let statsRecord = StudyStatsRecord(
                id: "primary_stats",
                totalReviews: legacyStats.totalReviews,
                correctCount: legacyStats.correctCount,
                incorrectCount: legacyStats.incorrectCount,
                currentStreak: legacyStats.currentStreak,
                lastStudied: legacyStats.lastStudied
            )
            modelContext.insert(statsRecord)
            UserDefaults.standard.removeObject(forKey: statsKey)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    func restoreSampleDecks() {
        seedInitialData()
    }

    private func seedInitialData() {
        let sample = Deck.sampleDeck
        modelContext.insert(sample)
        for card in sample.cards {
            card.deck = sample
            modelContext.insert(card)
        }

        let japanese = Deck.japaneseVocabDeck
        modelContext.insert(japanese)
        for card in japanese.cards {
            card.deck = japanese
            modelContext.insert(card)
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: hasSeededKey)
        fetchDecks()
    }

    // MARK: - Fetching
    func fetchDecks() {
        let descriptor = FetchDescriptor<Deck>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        do {
            self.decks = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch decks: \(error)")
            self.decks = []
        }
    }

    func fetchStats() {
        let descriptor = FetchDescriptor<StudyStatsRecord>()
        if let record = try? modelContext.fetch(descriptor).first {
            self.studyStats = StudyStats(
                totalReviews: record.totalReviews,
                correctCount: record.correctCount,
                incorrectCount: record.incorrectCount,
                currentStreak: record.currentStreak,
                lastStudied: record.lastStudied
            )
        } else {
            let newRecord = StudyStatsRecord()
            modelContext.insert(newRecord)
            try? modelContext.save()
            self.studyStats = StudyStats()
        }
    }

    private func saveStats() {
        let descriptor = FetchDescriptor<StudyStatsRecord>()
        if let record = try? modelContext.fetch(descriptor).first {
            record.totalReviews = studyStats.totalReviews
            record.correctCount = studyStats.correctCount
            record.incorrectCount = studyStats.incorrectCount
            record.currentStreak = studyStats.currentStreak
            record.lastStudied = studyStats.lastStudied
        } else {
            let newRecord = StudyStatsRecord(
                id: "primary_stats",
                totalReviews: studyStats.totalReviews,
                correctCount: studyStats.correctCount,
                incorrectCount: studyStats.incorrectCount,
                currentStreak: studyStats.currentStreak,
                lastStudied: studyStats.lastStudied
            )
            modelContext.insert(newRecord)
        }
        try? modelContext.save()
    }

    // MARK: - CRUD Operations
    func addDeck(_ deck: Deck) {
        modelContext.insert(deck)
        for card in deck.cards {
            card.deck = deck
            modelContext.insert(card)
        }
        try? modelContext.save()
        fetchDecks()
    }

    func deleteDeck(at offsets: IndexSet) {
        for index in offsets {
            if decks.indices.contains(index) {
                let deck = decks[index]
                modelContext.delete(deck)
            }
        }
        try? modelContext.save()
        fetchDecks()
    }

    func deleteDeck(byId id: UUID) {
        if let deck = decks.first(where: { $0.id == id }) {
            modelContext.delete(deck)
            try? modelContext.save()
            fetchDecks()
        }
    }

    func updateDeck(_ deck: Deck) {
        try? modelContext.save()
        fetchDecks()
    }

    func addCard(_ card: FlashCard, toDeckId deckId: UUID) {
        if let deck = decks.first(where: { $0.id == deckId }) {
            card.deck = deck
            deck.cards.append(card)
            modelContext.insert(card)
            try? modelContext.save()
            fetchDecks()
        }
    }

    func updateCard(_ card: FlashCard, inDeckId deckId: UUID) {
        try? modelContext.save()
        fetchDecks()
    }

    func deleteCard(cardId: UUID, fromDeckId deckId: UUID) {
        if let deck = decks.first(where: { $0.id == deckId }),
           let card = deck.cards.first(where: { $0.id == cardId }) {
            if let idx = deck.cards.firstIndex(where: { $0.id == cardId }) {
                deck.cards.remove(at: idx)
            }
            modelContext.delete(card)
            try? modelContext.save()
            fetchDecks()
        }
    }

    func recordReview(cardId: UUID, deckId: UUID, correct: Bool) {
        if let deck = decks.first(where: { $0.id == deckId }),
           let card = deck.cards.first(where: { $0.id == cardId }) {
            let now = Date()
            card.reviewCount += 1
            card.lastReviewed = now
            if correct {
                card.masteryLevel = min(5, card.masteryLevel + 1)
                studyStats.correctCount += 1
            } else {
                card.masteryLevel = max(0, card.masteryLevel - 1)
                studyStats.incorrectCount += 1
            }

            // Update daily streak
            let calendar = Calendar.current
            if let last = studyStats.lastStudied {
                if calendar.isDateInToday(last) {
                    studyStats.currentStreak = max(1, studyStats.currentStreak)
                } else if calendar.isDateInYesterday(last) {
                    studyStats.currentStreak += 1
                } else {
                    studyStats.currentStreak = 1
                }
            } else {
                studyStats.currentStreak = 1
            }

            studyStats.totalReviews += 1
            studyStats.lastStudied = now
            saveStats()
            try? modelContext.save()
            fetchDecks()
        }
    }

    func undoReview(
        cardId: UUID,
        deckId: UUID,
        wasCorrect: Bool,
        previousMastery: Int,
        previousReviewCount: Int,
        previousLastReviewed: Date?
    ) {
        if let deck = decks.first(where: { $0.id == deckId }),
           let card = deck.cards.first(where: { $0.id == cardId }) {
            card.masteryLevel = previousMastery
            card.reviewCount = previousReviewCount
            card.lastReviewed = previousLastReviewed

            if wasCorrect {
                studyStats.correctCount = max(0, studyStats.correctCount - 1)
            } else {
                studyStats.incorrectCount = max(0, studyStats.incorrectCount - 1)
            }
            studyStats.totalReviews = max(0, studyStats.totalReviews - 1)
            saveStats()
            try? modelContext.save()
            fetchDecks()
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
