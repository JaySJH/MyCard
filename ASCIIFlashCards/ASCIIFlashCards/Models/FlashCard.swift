import Foundation

// MARK: - FlashCard Model
struct FlashCard: Identifiable, Codable {
    var id: UUID
    var word: String
    var definition: String
    var example: String
    var partOfSpeech: PartOfSpeech
    var difficulty: Difficulty
    var tags: [String]
    var masteryLevel: Int       // 0-5
    var reviewCount: Int
    var lastReviewed: Date?
    var createdAt: Date

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
        createdAt: Date = Date()
    ) {
        self.id = id
        self.word = word
        self.definition = definition
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.difficulty = difficulty
        self.tags = tags
        self.masteryLevel = masteryLevel
        self.reviewCount = reviewCount
        self.lastReviewed = lastReviewed
        self.createdAt = createdAt
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
struct Deck: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var cards: [FlashCard]
    var createdAt: Date
    var colorTheme: DeckTheme

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
        self.description = description
        self.cards = cards
        self.createdAt = createdAt
        self.colorTheme = colorTheme
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
    static let sampleDeck = Deck(
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

    static let japaneseVocabDeck = Deck(
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
