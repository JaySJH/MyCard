import SwiftUI

enum StudyScope: String, CaseIterable {
    case all = "全部"
    case unmastered = "待加強"
}

struct ReviewHistoryItem {
    let index: Int
    let card: FlashCard
    let wasCorrect: Bool
    let previousMastery: Int
    let previousReviewCount: Int
    let previousLastReviewed: Date?
}

// MARK: - Study View (MUJI Paper Card Style)
struct StudyView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var speech = SpeechManager.shared

    let deck: Deck

    @State private var studyScope: StudyScope = .all
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var studyCards: [FlashCard] = []
    @State private var missedCards: [FlashCard] = []
    @State private var reviewHistory: [ReviewHistoryItem] = []
    @State private var isFinished: Bool = false
    @State private var isTransitioning: Bool = false
    @State private var flipDegree: Double = 0
    @State private var showHint: Bool = false
    @State private var dragOffset: CGSize = .zero

    var currentDeck: Deck {
        store.decks.first(where: { $0.id == deck.id }) ?? deck
    }

    var unmasteredCount: Int {
        currentDeck.cards.filter { $0.masteryLevel < 4 }.count
    }

    var accentColor: Color { Color.terminalColor(for: currentDeck.colorTheme) }
    var currentCard: FlashCard? { studyCards.indices.contains(currentIndex) ? studyCards[currentIndex] : nil }
    var progressRatio: Double {
        guard !studyCards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(studyCards.count)
    }

    var body: some View {
        ZStack {
            Color.mujiBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Minimalist Session Header ──
                sessionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if isFinished {
                    finishedView
                } else if let card = currentCard {
                    Spacer(minLength: 12)

                    // ── Paper Flashcard ──
                    paperFlashCard(card: card)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 20)

                    // ── Control Buttons ──
                    if isFlipped {
                        evaluationButtons(card: card)
                            .padding(.horizontal, 20)
                    } else {
                        flipControls(card: card)
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 24)
                } else {
                    emptyDeckView
                }
            }
        }
        .onAppear {
            setupStudySession()
        }
        .onDisappear {
            speech.stop()
        }
    }

    // MARK: - Session Header
    var sessionHeader: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentDeck.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text("\(studyCards.isEmpty ? 0 : min(currentIndex + 1, studyCards.count)) / \(studyCards.count)")
                            .font(.mujiCaption)
                            .foregroundColor(.mujiTextSecondary)

                        if sessionCorrect > 0 || sessionIncorrect > 0 {
                            HStack(spacing: 6) {
                                Text("✓ \(sessionCorrect)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.mujiSage)
                                Text("✕ \(sessionIncorrect)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.mujiCrimson)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    // Undo last review button
                    if !reviewHistory.isEmpty && !isFinished {
                        Button {
                            undoLastReview()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 11, weight: .medium))
                                Text("上一步")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.mujiTextSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(MujiPressableButtonStyle())
                        .accessibilityLabel("返回上一張單字卡")
                    }

                    // Auto-play pronunciation toggle
                    Button {
                        Haptics.selection()
                        speech.autoPlayOnStudy.toggle()
                        if speech.autoPlayOnStudy, let card = currentCard {
                            speech.speak(card.word, contextText: card.example)
                        }
                    } label: {
                        Image(systemName: speech.autoPlayOnStudy ? "speaker.wave.2.fill" : "speaker.slash")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(speech.autoPlayOnStudy ? accentColor : .mujiTextMuted)
                            .frame(width: 32, height: 32)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(MujiPressableButtonStyle())
                    .accessibilityLabel(speech.autoPlayOnStudy ? "自動發音：開啟" : "自動發音：關閉")

                    Button {
                        Haptics.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(MujiPressableButtonStyle())
                    .touchTarget()
                }
            }

            // Scope Filter Pills (All vs Unmastered) if deck has both mastered and unmastered cards
            if unmasteredCount > 0 && unmasteredCount < currentDeck.cards.count && !isFinished {
                HStack(spacing: 8) {
                    ForEach(StudyScope.allCases, id: \.self) { scope in
                        let isSelected = studyScope == scope
                        let count = scope == .all ? currentDeck.cards.count : unmasteredCount
                        Button {
                            guard studyScope != scope else { return }
                            Haptics.selection()
                            studyScope = scope
                            setupStudySession()
                        } label: {
                            Text("\(scope.rawValue) (\(count))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(isSelected ? Color.mujiTextPrimary : Color.mujiSecondarySurface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
            }

            // Continuous Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.mujiSecondarySurface)
                        .frame(height: 4)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * CGFloat(progressRatio), height: 4)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Flash Card Component (Apple HIG Fluid Gestures & Haptics)
    func paperFlashCard(card: FlashCard) -> some View {
        ZStack {
            cardBack(card: card)
                .rotation3DEffect(.degrees(flipDegree < -90 ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)

            cardFront(card: card)
                .rotation3DEffect(.degrees(flipDegree), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 340)
        .overlay(
            // Swipe Hints on Drag
            Group {
                if dragOffset.width > 40 {
                    HStack {
                        Spacer()
                        Text("已記住 ✓")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mujiSage)
                            .clipShape(Capsule())
                            .padding(16)
                    }
                } else if dragOffset.width < -40 {
                    HStack {
                        Text("✕ 還不熟")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mujiCrimson)
                            .clipShape(Capsule())
                            .padding(16)
                        Spacer()
                    }
                }
            }
            .animation(.easeInOut(duration: 0.15), value: dragOffset.width)
        )
        .offset(x: dragOffset.width, y: dragOffset.height * 0.15)
        .rotationEffect(.degrees(Double(dragOffset.width / 24)))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { gesture in
                    guard !isTransitioning else { return }
                    dragOffset = gesture.translation
                }
                .onEnded { gesture in
                    guard !isTransitioning else { return }
                    if gesture.translation.width > 100 {
                        isTransitioning = true
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset.width = 400
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            dragOffset = .zero
                            markCard(card: card, correct: true, bypassTransitionGuard: true)
                        }
                    } else if gesture.translation.width < -100 {
                        isTransitioning = true
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            dragOffset.width = -400
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            dragOffset = .zero
                            markCard(card: card, correct: false, bypassTransitionGuard: true)
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            guard !isTransitioning else { return }
            flipCard()
        }
    }

    // MARK: - Card Front
    func cardFront(card: FlashCard) -> some View {
        VStack(spacing: 0) {
            // Card top info
            HStack(spacing: 6) {
                Text(card.partOfSpeech.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mujiTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mujiSecondarySurface)
                    .clipShape(Capsule())

                difficultyBadge(card.difficulty)

                Spacer()

                // Mastery Dots (0 to 5)
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < card.masteryLevel ? accentColor : Color.mujiBorder)
                            .frame(width: 6, height: 6)
                    }
                }
            }

            Spacer()

            // Word + Pronunciation Button
            VStack(spacing: 12) {
                Text(card.word)
                    .font(.system(size: 34, weight: .light, design: .default))
                    .foregroundColor(.mujiTextPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)

                Button {
                    Haptics.light()
                    speech.speak(card.word, contextText: card.example)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                        Text("發音")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.mujiTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.mujiSecondarySurface)
                    .clipShape(Capsule())
                }
                .buttonStyle(MujiPressableButtonStyle())
            }

            // Smart Contextual Hint (Cloze example or masked hint instead of full spoiler)
            if showHint {
                VStack(spacing: 4) {
                    Text(smartHint(for: card))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mujiOchre)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.mujiOchre.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 16)
            }

            Spacer()

            // Card Bottom info
            HStack {
                if !card.tags.isEmpty {
                    Text(card.tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
                        .font(.system(size: 11))
                        .foregroundColor(.mujiTextMuted)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11))
                    Text("輕點卡片翻面")
                        .font(.system(size: 12))
                }
                .foregroundColor(.mujiTextMuted)
            }
        }
        .padding(24)
        .background(Color.mujiCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.mujiBorder, lineWidth: 0.8)
        )
    }

    // MARK: - Card Back
    func cardBack(card: FlashCard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text(card.word)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.mujiTextPrimary)

                Button {
                    Haptics.light()
                    speech.speak(card.word, contextText: card.example)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(accentColor)
                        .frame(width: 28, height: 28)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Circle())
                }
                .buttonStyle(MujiPressableButtonStyle())

                Spacer()

                difficultyBadge(card.difficulty)

                Text(card.partOfSpeech.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mujiTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mujiSecondarySurface)
                    .clipShape(Capsule())
            }

            Rectangle()
                .fill(Color.mujiBorder)
                .frame(height: 0.75)

            VStack(alignment: .leading, spacing: 4) {
                Text("中文釋義")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mujiTextMuted)
                Text(card.definition)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.mujiTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !card.example.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("實用例句")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.mujiTextMuted)

                        Button {
                            Haptics.light()
                            speech.speak(card.example, contextText: card.example, rate: 0.46)
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "speaker.wave.2")
                                    .font(.system(size: 10))
                                Text("朗讀例句")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.mujiTextSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(MujiPressableButtonStyle())
                    }

                    Text(card.example)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.mujiTextSecondary)
                        .italic()
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            Rectangle()
                .fill(Color.mujiBorder)
                .frame(height: 0.75)

            HStack {
                Text("已複習 \(card.reviewCount) 次")
                    .font(.system(size: 11))
                    .foregroundColor(.mujiTextMuted)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < card.masteryLevel ? accentColor : Color.mujiBorder)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.mujiCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.mujiBorder, lineWidth: 0.8)
        )
    }

    func difficultyBadge(_ difficulty: Difficulty) -> some View {
        let color: Color = difficulty == .easy ? .mujiSage : (difficulty == .medium ? .mujiOchre : .mujiCrimson)
        return Text(difficulty.localizedLabel)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 2.5)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    /// 產生不直接暴雷的智慧語境提示（優先使用例句挖空，若無例句則給予字數與部分遮罩提示）
    func smartHint(for card: FlashCard) -> String {
        if !card.example.isEmpty {
            let maskedExample = card.example.replacingOccurrences(
                of: card.word,
                with: "_____",
                options: .caseInsensitive
            )
            let defCount = card.definition.count
            let firstChar = card.definition.prefix(1)
            return "例句語境：\(maskedExample)\n（釋義開頭：「\(firstChar)...」共 \(defCount) 字）"
        } else {
            let def = card.definition
            if def.count <= 2 {
                return "釋義提示：共 \(def.count) 個字"
            }
            let prefixCount = max(1, def.count / 3)
            let shown = String(def.prefix(prefixCount))
            let hiddenCount = def.count - prefixCount
            return "釋義線索：\(shown)\(String(repeating: "○", count: min(hiddenCount, 6)))"
        }
    }

    // MARK: - Flip Controls
    func flipControls(card: FlashCard) -> some View {
        HStack(spacing: 12) {
            Button {
                guard !isTransitioning else { return }
                flipCard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                    Text("查看釋義")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.mujiButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.mujiTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(MujiPressableButtonStyle())

            Button {
                Haptics.light()
                withAnimation { showHint.toggle() }
            } label: {
                Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 16))
                    .foregroundColor(.mujiOchre)
                    .frame(width: 50, height: 50)
                    .background(Color.mujiCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.mujiBorder, lineWidth: 0.8)
                    )
            }
            .buttonStyle(MujiPressableButtonStyle())
            .touchTarget()
            .accessibilityLabel("顯示記憶線索提示")
        }
    }

    // MARK: - Evaluation Buttons (Apple HIG Roles: Secondary vs Primary)
    func evaluationButtons(card: FlashCard) -> some View {
        HStack(spacing: 12) {
            // Again button (還不熟) - Secondary
            Button {
                markCard(card: card, correct: false)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("還不熟")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.mujiCrimson)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.mujiCrimson.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.mujiCrimson.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(MujiPressableButtonStyle())
            .disabled(isTransitioning)

            // Got it button (已記住) - Primary
            Button {
                markCard(card: card, correct: true)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("已記住")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.mujiSage)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(MujiPressableButtonStyle())
            .disabled(isTransitioning)
        }
    }

    // MARK: - Finished View
    var finishedView: some View {
        VStack(spacing: 22) {
            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.mujiSage)

                Text("本次學習完成")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.mujiTextPrimary)

                Text("持續複習能讓記憶更為牢固")
                    .font(.mujiCallout)
                    .foregroundColor(.mujiTextSecondary)
            }

            let total = sessionCorrect + sessionIncorrect
            let pct = total > 0 ? Int(Double(sessionCorrect) / Double(total) * 100) : 0

            VStack(spacing: 14) {
                HStack {
                    Text("複習成果")
                        .font(.mujiHeadline)
                        .foregroundColor(.mujiTextPrimary)
                    Spacer()
                    Text("正確率 \(pct)%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mujiSage)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mujiSecondarySurface)
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.mujiSage)
                            .frame(width: geo.size.width * CGFloat(pct) / 100, height: 6)
                    }
                }
                .frame(height: 6)

                Divider()
                    .background(Color.mujiBorder)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("已掌握")
                            .font(.mujiCaption)
                            .foregroundColor(.mujiTextSecondary)
                        Text("\(sessionCorrect) 張")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.mujiSage)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("需再加強")
                            .font(.mujiCaption)
                            .foregroundColor(.mujiTextSecondary)
                        Text("\(sessionIncorrect) 張")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.mujiCrimson)
                    }
                }
            }
            .mujiCard(cornerRadius: 12, padding: 20)
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                // Quick retry missed cards only
                if !missedCards.isEmpty {
                    Button {
                        retryMissedCards()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("只重練答錯的單字 (\(missedCards.count) 張)")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.mujiCrimson)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.mujiCrimson.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.mujiCrimson.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(MujiPressableButtonStyle())
                    .padding(.horizontal, 24)
                }

                HStack(spacing: 12) {
                    Button {
                        setupStudySession()
                    } label: {
                        Text("再複習一次")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(MujiPressableButtonStyle())

                    Button {
                        dismiss()
                    } label: {
                        Text("完成學習")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiButtonText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mujiTextPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(MujiPressableButtonStyle())
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    // MARK: - Empty Deck View
    var emptyDeckView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(studyScope == .unmastered ? "太棒了！此單字庫所有單字皆已熟練" : "此單字庫尚無卡片")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            if studyScope == .unmastered && !currentDeck.cards.isEmpty {
                Button {
                    studyScope = .all
                    setupStudySession()
                } label: {
                    Text("複習全部單字 (\(currentDeck.cards.count) 張)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mujiButtonText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.mujiTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("返回")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mujiButtonText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.mujiTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            Spacer()
        }
    }

    // MARK: - Logic
    func setupStudySession() {
        let pool: [FlashCard]
        if studyScope == .unmastered {
            let unmastered = currentDeck.cards.filter { $0.masteryLevel < 4 }
            pool = unmastered.isEmpty ? currentDeck.cards : unmastered
        } else {
            pool = currentDeck.cards
        }
        // Sort with less-mastered cards prioritized slightly while maintaining randomness
        studyCards = pool.shuffled().sorted { $0.masteryLevel < $1.masteryLevel }
        currentIndex = 0
        isFlipped = false
        sessionCorrect = 0
        sessionIncorrect = 0
        missedCards = []
        reviewHistory = []
        isFinished = false
        isTransitioning = false
        showHint = false
        flipDegree = 0

        if speech.autoPlayOnStudy, let first = studyCards.first {
            speech.speak(first.word, contextText: first.example)
        }
    }

    func retryMissedCards() {
        studyCards = missedCards.shuffled()
        currentIndex = 0
        isFlipped = false
        sessionCorrect = 0
        sessionIncorrect = 0
        missedCards = []
        reviewHistory = []
        isFinished = false
        isTransitioning = false
        showHint = false
        flipDegree = 0

        if speech.autoPlayOnStudy, let first = studyCards.first {
            speech.speak(first.word, contextText: first.example)
        }
    }

    func flipCard() {
        Haptics.light()
        withAnimation(.easeInOut(duration: 0.35)) {
            flipDegree = isFlipped ? 0 : -180
            isFlipped.toggle()
        }
        showHint = false
    }

    func markCard(card: FlashCard, correct: Bool, bypassTransitionGuard: Bool = false) {
        if !bypassTransitionGuard {
            guard !isTransitioning else { return }
            isTransitioning = true
        }

        // Save history snapshot before updating store
        let historyItem = ReviewHistoryItem(
            index: currentIndex,
            card: card,
            wasCorrect: correct,
            previousMastery: card.masteryLevel,
            previousReviewCount: card.reviewCount,
            previousLastReviewed: card.lastReviewed
        )
        reviewHistory.append(historyItem)

        if correct {
            Haptics.medium()
            sessionCorrect += 1
        } else {
            Haptics.warning()
            sessionIncorrect += 1
            if !missedCards.contains(where: { $0.id == card.id }) {
                missedCards.append(card)
            }
        }
        store.recordReview(cardId: card.id, deckId: currentDeck.id, correct: correct)

        withAnimation(.easeInOut(duration: 0.22)) {
            flipDegree = 0
            isFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showHint = false
            if currentIndex + 1 >= studyCards.count {
                Haptics.success()
                withAnimation {
                    isFinished = true
                    isTransitioning = false
                }
            } else {
                withAnimation {
                    currentIndex += 1
                    isTransitioning = false
                }
                if speech.autoPlayOnStudy, let next = currentCard {
                    speech.speak(next.word, contextText: next.example)
                }
            }
        }
    }

    func undoLastReview() {
        guard !isTransitioning, let last = reviewHistory.popLast() else { return }
        Haptics.light()

        store.undoReview(
            cardId: last.card.id,
            deckId: currentDeck.id,
            wasCorrect: last.wasCorrect,
            previousMastery: last.previousMastery,
            previousReviewCount: last.previousReviewCount,
            previousLastReviewed: last.previousLastReviewed
        )

        if last.wasCorrect {
            sessionCorrect = max(0, sessionCorrect - 1)
        } else {
            sessionIncorrect = max(0, sessionIncorrect - 1)
            missedCards.removeAll { $0.id == last.card.id }
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isFinished = false
            currentIndex = last.index
            isFlipped = false
            flipDegree = 0
            showHint = false
        }
    }
}

#Preview {
    StudyView(deck: Deck.sampleDeck)
        .environmentObject(DeckStore())
}
