import SwiftUI

// MARK: - Study View (MUJI Paper Card Style)
struct StudyView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss

    let deck: Deck

    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var studyCards: [FlashCard] = []
    @State private var isFinished: Bool = false
    @State private var flipDegree: Double = 0
    @State private var showHint: Bool = false

    var accentColor: Color { Color.terminalColor(for: deck.colorTheme) }
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
                    Spacer(minLength: 16)

                    // ── Paper Flashcard ──
                    paperFlashCard(card: card)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 24)

                    // ── Control Buttons ──
                    if isFlipped {
                        evaluationButtons(card: card)
                            .padding(.horizontal, 20)
                    } else {
                        flipControls
                            .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 28)
                } else {
                    emptyDeckView
                }
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            setupStudySession()
        }
    }

    // MARK: - Session Header
    var sessionHeader: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(deck.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                        .lineLimit(1)
                    Text("\(min(currentIndex + 1, studyCards.count)) / \(studyCards.count)")
                        .font(.mujiCaption)
                        .foregroundColor(.mujiTextSecondary)
                }

                Spacer()

                HStack(spacing: 8) {
                    if sessionCorrect > 0 || sessionIncorrect > 0 {
                        HStack(spacing: 6) {
                            Text("✓ \(sessionCorrect)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.mujiSage)
                            Text("✕ \(sessionIncorrect)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.mujiCrimson)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Capsule())
                    }

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Circle())
                    }
                }
            }

            // Continuous Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.mujiSecondarySurface)
                        .frame(height: 3)
                    Capsule()
                        .fill(accentColor)
                        .frame(width: geo.size.width * CGFloat(progressRatio), height: 3)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: - Flash Card Component
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
        .contentShape(Rectangle())
        .onTapGesture {
            flipCard()
        }
    }

    // MARK: - Card Front
    func cardFront(card: FlashCard) -> some View {
        VStack(spacing: 0) {
            // Card top info
            HStack {
                Text(card.partOfSpeech.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mujiTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mujiSecondarySurface)
                    .clipShape(Capsule())

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

            // Word
            Text(card.word)
                .font(.system(size: 34, weight: .light, design: .default))
                .foregroundColor(.mujiTextPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 8)

            // Hint
            if showHint {
                Text("提示：\(String(card.definition.prefix(25)))...")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.mujiOchre)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mujiOchre.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
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
            HStack {
                Text(card.word)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.mujiTextPrimary)
                Spacer()
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("實用例句")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.mujiTextMuted)
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

    // MARK: - Flip Controls
    var flipControls: some View {
        HStack(spacing: 12) {
            Button {
                flipCard()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                    Text("查看釋義")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.mujiTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                withAnimation { showHint.toggle() }
            } label: {
                Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                    .font(.system(size: 16))
                    .foregroundColor(.mujiOchre)
                    .frame(width: 48, height: 48)
                    .background(Color.mujiCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.mujiBorder, lineWidth: 0.8)
                    )
            }
        }
    }

    // MARK: - Evaluation Buttons
    func evaluationButtons(card: FlashCard) -> some View {
        HStack(spacing: 12) {
            // Again button (還不熟)
            Button {
                markCard(card: card, correct: false)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("還不熟")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.mujiCrimson)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.mujiCrimson.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.mujiCrimson.opacity(0.3), lineWidth: 1)
                )
            }

            // Got it button (已記住)
            Button {
                markCard(card: card, correct: true)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("已記住")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.mujiSage)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    // MARK: - Finished View
    var finishedView: some View {
        VStack(spacing: 24) {
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

            HStack(spacing: 14) {
                Button {
                    setupStudySession()
                } label: {
                    Text("再複習一次")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Button {
                    dismiss()
                } label: {
                    Text("完成學習")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.mujiTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Spacer()
        }
    }

    // MARK: - Empty Deck View
    var emptyDeckView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("此單字庫尚無卡片")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            Button {
                dismiss()
            } label: {
                Text("返回")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.mujiTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
        }
    }

    // MARK: - Logic
    func setupStudySession() {
        studyCards = deck.cards.shuffled()
        currentIndex = 0
        isFlipped = false
        sessionCorrect = 0
        sessionIncorrect = 0
        isFinished = false
        showHint = false
        flipDegree = 0
    }

    func flipCard() {
        withAnimation(.easeInOut(duration: 0.35)) {
            flipDegree = isFlipped ? 0 : -180
            isFlipped.toggle()
        }
        showHint = false
    }

    func markCard(card: FlashCard, correct: Bool) {
        store.recordReview(cardId: card.id, deckId: deck.id, correct: correct)
        if correct { sessionCorrect += 1 } else { sessionIncorrect += 1 }

        withAnimation(.easeInOut(duration: 0.25)) {
            flipDegree = 0
            isFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showHint = false
            if currentIndex + 1 >= studyCards.count {
                withAnimation { isFinished = true }
            } else {
                withAnimation { currentIndex += 1 }
            }
        }
    }
}

#Preview {
    StudyView(deck: Deck.sampleDeck)
        .environmentObject(DeckStore())
        .preferredColorScheme(.light)
}
