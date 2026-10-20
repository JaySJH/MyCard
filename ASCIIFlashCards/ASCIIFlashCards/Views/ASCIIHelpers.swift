import SwiftUI
import AVFoundation
import NaturalLanguage

// MARK: - Smart Speech Synthesizer (Auto Language Detection & TTS)
@MainActor
final class SpeechManager: ObservableObject {
    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()
    @AppStorage("autoPlayPronunciation") var autoPlayOnStudy: Bool = false

    private init() {}

    /// 根據文字與上下文（如例句或釋義）自動偵測語言並發音
    func speak(_ text: String, contextText: String = "", rate: Float = 0.48) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Configure audio session so sound plays even if silent switch is on
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore audio session error in simulator/preview
        }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let languageCode = detectLanguage(for: trimmed, contextText: contextText)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode) ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// 智慧判斷單字或例句的語系 (支援英、日、韓、中及歐語自動識別)
    func detectLanguage(for text: String, contextText: String = "") -> String {
        // 1. 若文字本身或上下文包含日文平假名 / 片假名，優先判定為日文 (解決純漢字日文單字如「経験」、「笑顔」的識別)
        if containsJapaneseKana(text) || containsJapaneseKana(contextText) {
            return "ja-JP"
        }

        // 2. 若包含韓文諺文
        if containsKoreanHangul(text) {
            return "ko-KR"
        }

        // 3. 若全為 ASCII 拉丁字母，預設使用英文發音 (避免短單字被誤判為其他拉丁語系)
        let isLatinOnly = text.unicodeScalars.allSatisfy {
            CharacterSet.letters.inverted.contains($0) || ($0.value >= 0x0041 && $0.value <= 0x024F)
        }
        if isLatinOnly {
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)
            if let lang = recognizer.dominantLanguage,
               let confidence = recognizer.languageHypotheses(withMaximum: 1)[lang],
               confidence > 0.85 {
                switch lang {
                case .french:  return "fr-FR"
                case .german:  return "de-DE"
                case .spanish: return "es-ES"
                default:       return "en-US"
                }
            }
            return "en-US"
        }

        // 4. 使用 NaturalLanguage 進行一般識別
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        if let lang = recognizer.dominantLanguage {
            switch lang {
            case .japanese:           return "ja-JP"
            case .korean:             return "ko-KR"
            case .traditionalChinese: return "zh-TW"
            case .simplifiedChinese:  return "zh-CN"
            case .french:             return "fr-FR"
            case .german:             return "de-DE"
            case .spanish:            return "es-ES"
            default:                  return "en-US"
            }
        }

        // 5. 含中文字元則預設繁體中文
        if containsCJK(text) {
            return "zh-TW"
        }

        return "en-US"
    }

    private func containsJapaneseKana(_ str: String) -> Bool {
        str.unicodeScalars.contains { scalar in
            (scalar.value >= 0x3040 && scalar.value <= 0x309F) || // Hiragana
            (scalar.value >= 0x30A0 && scalar.value <= 0x30FF)    // Katakana
        }
    }

    private func containsKoreanHangul(_ str: String) -> Bool {
        str.unicodeScalars.contains { scalar in
            (scalar.value >= 0xAC00 && scalar.value <= 0xD7AF) ||
            (scalar.value >= 0x1100 && scalar.value <= 0x11FF)
        }
    }

    private func containsCJK(_ str: String) -> Bool {
        str.unicodeScalars.contains { scalar in
            scalar.value >= 0x4E00 && scalar.value <= 0x9FFF
        }
    }
}

// MARK: - MUJI Color Palette & Design System (Apple HIG Dynamic Adaptation)
extension Color {
    // ── 核心基礎色彩 (和紙與自然質感，支援深淺色動態切換) ──
    /// 和紙暖米白底色 (淺色 #F7F5F0 / 深色 #1C1B1A 墨炭沉靜底色)
    static let mujiBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.106, blue: 0.102, alpha: 1.0)
            : UIColor(red: 0.969, green: 0.961, blue: 0.941, alpha: 1.0)
    })

    /// 純白紙卡表面 (淺色 #FFFFFF / 深色 #22201E 深炭卡片表面)
    static let mujiCardSurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.150, green: 0.145, blue: 0.141, alpha: 1.0)
            : UIColor.white
    })

    /// 淺亞麻灰微底色 (淺色 #EFECE6 / 深色 #2D2A28 亞麻深灰)
    static let mujiSecondarySurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.196, green: 0.188, blue: 0.180, alpha: 1.0)
            : UIColor(red: 0.937, green: 0.925, blue: 0.902, alpha: 1.0)
    })

    /// 柔和素雅邊框線 (淺色 #E5E0D8 / 深色 #33302D 深墨灰線條)
    static let mujiBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.235, green: 0.224, blue: 0.216, alpha: 1.0)
            : UIColor(red: 0.898, green: 0.878, blue: 0.847, alpha: 1.0)
    })

    // ── 文字層級色彩 (動態階層高對比，符合 HIG 可讀性規範) ──
    /// 溫潤炭墨黑 (淺色 #2D2B29 / 深色 #F5F3EF 柔和白)
    static let mujiTextPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.953, blue: 0.941, alpha: 1.0)
            : UIColor(red: 0.176, green: 0.169, blue: 0.161, alpha: 1.0)
    })

    /// 主按鈕反白文字色 (淺色 #FFFFFF 純白 / 深色 #1C1B1A 深炭墨黑，避免深色模式白底白字)
    static let mujiButtonText = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.110, green: 0.106, blue: 0.102, alpha: 1.0)
            : UIColor.white
    })

    /// 淺墨灰 (副標題、詞性、說明)
    static let mujiTextSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.722, green: 0.706, blue: 0.686, alpha: 1.0)
            : UIColor(red: 0.490, green: 0.475, blue: 0.443, alpha: 1.0)
    })

    /// 淡麻灰 (次要提示、計數、邊緣資訊)
    static let mujiTextMuted = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.549, green: 0.533, blue: 0.510, alpha: 1.0)
            : UIColor(red: 0.682, green: 0.663, blue: 0.624, alpha: 1.0)
    })

    // ── 自然植物與礦物色 (Accent Colors) ──
    /// #82252B 無印經典暗絳紅
    static let mujiCrimson          = Color(red: 0.550, green: 0.160, blue: 0.180)
    /// #63785E 若草 / 鼠苔綠
    static let mujiSage             = Color(red: 0.400, green: 0.490, blue: 0.380)
    /// #B8864E 柴染 / 芥子黃
    static let mujiOchre            = Color(red: 0.740, green: 0.540, blue: 0.320)
    /// #4F677A 鐵紺 / 藍灰
    static let mujiSlateBlue        = Color(red: 0.330, green: 0.420, blue: 0.490)
    /// #4A4744 薄墨 / 炭灰
    static let mujiCharcoal         = Color(red: 0.310, green: 0.298, blue: 0.286)

    // ── 向下相容映射 ──
    static let screenBg      = mujiBackground
    static let cardBg        = mujiCardSurface
    static let highlightBg   = mujiSecondarySurface
    static let terminalGreen = mujiSage
    static let terminalAmber = mujiOchre
    static let terminalCyan  = mujiSlateBlue
    static let terminalRed   = mujiCrimson

    static func terminalColor(for theme: DeckTheme) -> Color {
        switch theme {
        case .green: return .mujiSage
        case .amber: return .mujiOchre
        case .cyan:  return .mujiSlateBlue
        case .white: return .mujiCharcoal
        case .red:   return .mujiCrimson
        }
    }
}

// MARK: - HIG Tactile Feedback (Haptics)
enum Haptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - HIG Compliant Button Press Styles
/// 為所有自訂按鈕提供符合 HIG 規範的微觸感回饋與縮放狀態
struct MujiPressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var opacity: Double = 0.88

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// 卡片專用點選樣式 (輕微沉降感與觸覺回饋)
struct MujiCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - MUJI Typography
extension Font {
    static let mujiLargeTitle = Font.system(size: 26, weight: .light, design: .default)
    static let mujiTitle      = Font.system(size: 20, weight: .medium, design: .default)
    static let mujiHeadline   = Font.system(size: 16, weight: .semibold, design: .default)
    static let mujiBody       = Font.system(size: 15, weight: .regular, design: .default)
    static let mujiCallout    = Font.system(size: 13, weight: .regular, design: .default)
    static let mujiCaption    = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - View Modifiers (Paper Card & HIG UI)
struct MujiCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.mujiCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.mujiBorder, lineWidth: 0.75)
            )
    }
}

extension View {
    func mujiCard(cornerRadius: CGFloat = 14, padding: CGFloat = 16) -> some View {
        self.modifier(MujiCardStyle(cornerRadius: cornerRadius, padding: padding))
    }

    /// 確保按鈕觸控區域符合 Apple HIG 最小 44x44 pt 規範
    func touchTarget(minSize: CGFloat = 44) -> some View {
        self.frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

// MARK: - Typography Helper
extension View {
    func terminalFont(size: CGFloat, bold: Bool = false) -> some View {
        self.font(.system(size: size, weight: bold ? .semibold : .regular, design: .default))
    }
}

// MARK: - Legacy ASCII Helpers (Kept for safe build compatibility)
enum ASCIIArt {
    static func boxTop(width: Int) -> String { "" }
    static func boxBottom(width: Int) -> String { "" }
    static func boxRow(_ text: String, width: Int, align: TextAlignment = .center) -> String { text }
    static func boxDivider(width: Int) -> String { "" }
    static func padText(_ text: String, toWidth width: Int, align: TextAlignment) -> String { text }
    static func visibleLength(_ text: String) -> Int { text.count }

    static func progressBar(value: Double, max: Double, width: Int = 10) -> String {
        let pct = max > 0 ? Int((value / max) * 100) : 0
        return "\(pct)%"
    }

    static let cardFront = ""
    static let cardBack = ""
    static let brainIcon = ""
    static let terminalIcon = ""
    static let trophyIcon = ""
    static let fireIcon = ""

    static func masteryStars(_ level: Int) -> String {
        String(repeating: "★", count: level) + String(repeating: "☆", count: max(0, 5 - level))
    }

    static var cursor: String { "" }
    static func separator(char: Character = "-", width: Int = 34) -> String { "" }
    static func formatCard(word: String, pos: String, difficulty: String) -> [String] { [word] }
}
