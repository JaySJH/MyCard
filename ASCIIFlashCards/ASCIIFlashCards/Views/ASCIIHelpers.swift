import SwiftUI

// MARK: - MUJI Color Palette & Design System
extension Color {
    // ── 核心基礎色彩 (和紙與自然質感) ──
    /// #F7F5F0 和紙暖米白底色
    static let mujiBackground       = Color(red: 0.969, green: 0.961, blue: 0.941)
    /// #FFFFFF 純白紙卡表面
    static let mujiCardSurface      = Color.white
    /// #EFECE6 淺亞麻灰微底色
    static let mujiSecondarySurface = Color(red: 0.937, green: 0.925, blue: 0.902)
    /// #E5E0D8 柔和素雅邊框線
    static let mujiBorder           = Color(red: 0.898, green: 0.878, blue: 0.847)

    // ── 文字層級色彩 ──
    /// #2D2B29 溫潤炭墨黑 (主要標題、內文)
    static let mujiTextPrimary      = Color(red: 0.176, green: 0.169, blue: 0.161)
    /// #7D7971 淺墨灰 (副標題、詞性、說明)
    static let mujiTextSecondary    = Color(red: 0.490, green: 0.475, blue: 0.443)
    /// #AEA99F 淡麻灰 (次要提示、計數、邊緣資訊)
    static let mujiTextMuted        = Color(red: 0.682, green: 0.663, blue: 0.624)

    // ── 自然植物與礦物色 (Accent Colors) ──
    /// #82252B 無印經典暗絳紅
    static let mujiCrimson          = Color(red: 0.510, green: 0.145, blue: 0.169)
    /// #63785E 若草 / 鼠苔綠
    static let mujiSage             = Color(red: 0.388, green: 0.471, blue: 0.369)
    /// #B8864E 柴染 / 芥子黃
    static let mujiOchre            = Color(red: 0.722, green: 0.525, blue: 0.306)
    /// #4F677A 鐵紺 / 藍灰
    static let mujiSlateBlue        = Color(red: 0.310, green: 0.404, blue: 0.478)
    /// #4A4744 薄墨 / 炭灰
    static let mujiCharcoal         = Color(red: 0.290, green: 0.278, blue: 0.267)

    // ── 向下相容映射 (重定向至無印色盤) ──
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

// MARK: - MUJI Typography
extension Font {
    static let mujiLargeTitle = Font.system(size: 26, weight: .light, design: .default)
    static let mujiTitle      = Font.system(size: 20, weight: .medium, design: .default)
    static let mujiHeadline   = Font.system(size: 16, weight: .semibold, design: .default)
    static let mujiBody       = Font.system(size: 15, weight: .regular, design: .default)
    static let mujiCallout    = Font.system(size: 13, weight: .regular, design: .default)
    static let mujiCaption    = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - View Modifiers (Paper Card & Clean UI)
struct MujiCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.mujiCardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.mujiBorder, lineWidth: 0.75)
            )
    }
}

extension View {
    func mujiCard(cornerRadius: CGFloat = 12, padding: CGFloat = 16) -> some View {
        self.modifier(MujiCardStyle(cornerRadius: cornerRadius, padding: padding))
    }
}

// MARK: - Typography Helper (Replaced Monospace with Clean Humanist Sans)
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
