import Foundation
import SwiftData

// MARK: - FlashCard Model
@Model
final class FlashCard: Identifiable {
    var id: UUID = UUID()
    var word: String = ""
    var definition: String = ""
    var example: String = ""
    var partOfSpeechRaw: String = PartOfSpeech.noun.rawValue
    var difficultyRaw: String = Difficulty.medium.rawValue
    var tags: [String] = []
    var masteryLevel: Int = 0       // 0-5
    var reviewCount: Int = 0
    var lastReviewed: Date? = nil
    var createdAt: Date = Date()
    var deck: Deck? = nil

    var partOfSpeech: PartOfSpeech {
        get { PartOfSpeech(rawValue: partOfSpeechRaw) ?? .noun }
        set { partOfSpeechRaw = newValue.rawValue }
    }

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        word: String,
        definition: String,
        example: String = "",
        partOfSpeech: PartOfSpeech = .noun,
        difficulty: Difficulty = .medium,
        tags: [String] = [],
        masteryLevel: Int = 0,
        reviewCount: Int = 0,
        lastReviewed: Date? = nil,
        createdAt: Date = Date(),
        deck: Deck? = nil
    ) {
        self.id = id
        self.word = word
        self.definition = definition
        self.example = example
        self.partOfSpeechRaw = partOfSpeech.rawValue
        self.difficultyRaw = difficulty.rawValue
        self.tags = tags
        self.masteryLevel = masteryLevel
        self.reviewCount = reviewCount
        self.lastReviewed = lastReviewed
        self.createdAt = createdAt
        self.deck = deck
    }
}

// MARK: - Part Of Speech
enum PartOfSpeech: String, CaseIterable, Codable {
    case noun       = "n."
    case verb       = "v."
    case adjective  = "adj."
    case adverb     = "adv."
    case pronoun    = "pron."
    case preposition = "prep."
    case conjunction = "conj."
    case interjection = "interj."

    var label: String {
        switch self {
        case .noun:         return "NOUN"
        case .verb:         return "VERB"
        case .adjective:    return "ADJ"
        case .adverb:       return "ADV"
        case .pronoun:      return "PRON"
        case .preposition:  return "PREP"
        case .conjunction:  return "CONJ"
        case .interjection: return "INTERJ"
        }
    }

    var asciiSymbol: String {
        switch self {
        case .noun:         return "[N]"
        case .verb:         return "[V]"
        case .adjective:    return "[A]"
        case .adverb:       return "[D]"
        case .pronoun:      return "[P]"
        case .preposition:  return "[R]"
        case .conjunction:  return "[C]"
        case .interjection: return "[!]"
        }
    }
}

// MARK: - Difficulty
enum Difficulty: String, CaseIterable, Codable {
    case easy   = "EASY"
    case medium = "MEDIUM"
    case hard   = "HARD"

    var localizedLabel: String {
        switch self {
        case .easy:   return "簡單"
        case .medium: return "中等"
        case .hard:   return "挑戰"
        }
    }

    var sortOrder: Int {
        switch self {
        case .hard:   return 0
        case .medium: return 1
        case .easy:   return 2
        }
    }

    var asciiBar: String {
        switch self {
        case .easy:   return "[###      ]"
        case .medium: return "[######   ]"
        case .hard:   return "[#########]"
        }
    }

    var stars: String {
        switch self {
        case .easy:   return "*  "
        case .medium: return "** "
        case .hard:   return "***"
        }
    }
}

// MARK: - Deck Model
@Model
final class Deck: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var deckDescription: String = ""
    var createdAt: Date = Date()
    var colorThemeRaw: String = DeckTheme.green.rawValue

    @Relationship(deleteRule: .cascade, inverse: \FlashCard.deck)
    var cards: [FlashCard] = []

    var description: String {
        get { deckDescription }
        set { deckDescription = newValue }
    }

    var colorTheme: DeckTheme {
        get { DeckTheme(rawValue: colorThemeRaw) ?? .green }
        set { colorThemeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        cards: [FlashCard] = [],
        createdAt: Date = Date(),
        colorTheme: DeckTheme = .green
    ) {
        self.id = id
        self.name = name
        self.deckDescription = description
        self.cards = cards
        self.createdAt = createdAt
        self.colorThemeRaw = colorTheme.rawValue
        for card in cards {
            card.deck = self
        }
    }

    var masteredCount: Int {
        cards.filter { $0.masteryLevel >= 4 }.count
    }

    var progressPercent: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(masteredCount) / Double(cards.count) * 100
    }

    var asciiProgressBar: String {
        let filled = Int(progressPercent / 10)
        let empty = 10 - filled
        return "[" + String(repeating: "#", count: filled) + String(repeating: "-", count: empty) + "]"
    }
}

// MARK: - StudyStats Record Model
@Model
final class StudyStatsRecord {
    var id: String = "primary_stats"
    var totalReviews: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var currentStreak: Int = 0
    var lastStudied: Date? = nil

    init(
        id: String = "primary_stats",
        totalReviews: Int = 0,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        currentStreak: Int = 0,
        lastStudied: Date? = nil
    ) {
        self.id = id
        self.totalReviews = totalReviews
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.currentStreak = currentStreak
        self.lastStudied = lastStudied
    }
}

// MARK: - Deck Theme
enum DeckTheme: String, CaseIterable, Codable {
    case green  = "GREEN"
    case amber  = "AMBER"
    case cyan   = "CYAN"
    case white  = "WHITE"
    case red    = "RED"

    var terminalColor: TerminalColor {
        switch self {
        case .green: return .green
        case .amber: return .amber
        case .cyan:  return .cyan
        case .white: return .white
        case .red:   return .red
        }
    }
}

// MARK: - Terminal Color
enum TerminalColor {
    case green, amber, cyan, white, red

    var primary: (r: Double, g: Double, b: Double) {
        switch self {
        case .green: return (0.0, 1.0, 0.0)
        case .amber: return (1.0, 0.75, 0.0)
        case .cyan:  return (0.0, 1.0, 1.0)
        case .white: return (0.9, 0.9, 0.9)
        case .red:   return (1.0, 0.2, 0.2)
        }
    }
}

// MARK: - Mastery Level Description
extension Int {
    var masteryLabel: String {
        switch self {
        case 0: return "[----------] NEW"
        case 1: return "[##--------] LEARNING"
        case 2: return "[####------] FAMILIAR"
        case 3: return "[######----] GOOD"
        case 4: return "[########--] GREAT"
        case 5: return "[##########] MASTERED"
        default: return "[----------] UNKNOWN"
        }
    }
}

// MARK: - Sample Data
extension Deck {
    static var sampleDeck: Deck {
        Deck(
            name: "English Vocabulary",
            description: "Common English words",
            cards: [
                FlashCard(
                    word: "ephemeral",
                    definition: "Lasting for a very short time",
                    example: "The ephemeral beauty of cherry blossoms.",
                    partOfSpeech: .adjective,
                    difficulty: .hard,
                    tags: ["literary", "time"],
                    masteryLevel: 2
                ),
                FlashCard(
                    word: "serendipity",
                    definition: "The occurrence of events by chance in a happy way",
                    example: "It was serendipity that we met at that cafe.",
                    partOfSpeech: .noun,
                    difficulty: .medium,
                    tags: ["luck", "fate"],
                    masteryLevel: 3
                ),
                FlashCard(
                    word: "eloquent",
                    definition: "Fluent or persuasive in speaking or writing",
                    example: "She gave an eloquent speech at the ceremony.",
                    partOfSpeech: .adjective,
                    difficulty: .medium,
                    tags: ["speech", "language"],
                    masteryLevel: 4
                ),
                FlashCard(
                    word: "ubiquitous",
                    definition: "Present, appearing, or found everywhere",
                    example: "Smartphones are ubiquitous in modern life.",
                    partOfSpeech: .adjective,
                    difficulty: .hard,
                    tags: ["everywhere"],
                    masteryLevel: 1
                ),
                FlashCard(
                    word: "pragmatic",
                    definition: "Dealing with things sensibly and realistically",
                    example: "We need a pragmatic approach to solve this.",
                    partOfSpeech: .adjective,
                    difficulty: .medium,
                    tags: ["practical"],
                    masteryLevel: 3
                ),
                FlashCard(
                    word: "meticulous",
                    definition: "Showing great attention to detail; very careful",
                    example: "She was meticulous in her research.",
                    partOfSpeech: .adjective,
                    difficulty: .medium,
                    tags: ["careful", "detail"],
                    masteryLevel: 0
                ),
                FlashCard(
                    word: "persevere",
                    definition: "Continue in a course of action despite difficulty",
                    example: "You must persevere to achieve your goals.",
                    partOfSpeech: .verb,
                    difficulty: .easy,
                    tags: ["determination"],
                    masteryLevel: 5
                ),
                FlashCard(
                    word: "ambiguous",
                    definition: "Open to more than one interpretation",
                    example: "The instructions were ambiguous and confusing.",
                    partOfSpeech: .adjective,
                    difficulty: .medium,
                    tags: ["unclear"],
                    masteryLevel: 2
                )
            ],
            colorTheme: .green
        )
    }

    static var japaneseVocabDeck: Deck {
        Deck(
            name: "JLPT N3 Vocab",
            description: "Japanese N3 level vocabulary",
            cards: [
                FlashCard(
                    word: "経験",
                    definition: "Experience (けいけん)",
                    example: "仕事の経験が大切です。",
                    partOfSpeech: .noun,
                    difficulty: .medium,
                    tags: ["jlpt", "n3"],
                    masteryLevel: 3
                ),
                FlashCard(
                    word: "複雑",
                    definition: "Complex, complicated (ふくざつ)",
                    example: "この問題は複雑です。",
                    partOfSpeech: .adjective,
                    difficulty: .hard,
                    tags: ["jlpt", "n3"],
                    masteryLevel: 1
                ),
                FlashCard(
                    word: "笑顔",
                    definition: "Smiling face (えがお)",
                    example: "彼女はいつも笑顔です。",
                    partOfSpeech: .noun,
                    difficulty: .easy,
                    tags: ["jlpt", "n3", "emotion"],
                    masteryLevel: 4
                )
            ],
            colorTheme: .cyan
        )
    }
}
