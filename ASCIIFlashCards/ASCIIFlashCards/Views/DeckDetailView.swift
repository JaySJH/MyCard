import SwiftUI

enum CardSortOption: String, CaseIterable {
    case newest = "最新建立"
    case lowestMastery = "最不熟優先"
    case hardest = "難度最高"
    case alphabetical = "字首 A-Z"
}

// MARK: - Deck Detail View (MUJI Clean Paper Style)
struct DeckDetailView: View {
    @EnvironmentObject var store: DeckStore
    @State var deck: Deck
    @State private var showAddCard = false
    @State private var showEditDeck = false
    @State private var editingCard: FlashCard? = nil
    @State private var cardPendingDelete: FlashCard? = nil
    @State private var showStudy = false
    @State private var searchText = ""
    @State private var sortOption: CardSortOption = .newest
    @State private var selectedTag: String? = nil
    @Environment(\.dismiss) var dismiss

    var accentColor: Color { Color.terminalColor(for: currentDeck.colorTheme) }

    // Always sync deck from store
    var currentDeck: Deck {
        store.decks.first(where: { $0.id == deck.id }) ?? deck
    }

    var allTags: [String] {
        let tags = currentDeck.cards.flatMap { $0.tags }
        return Array(Set(tags)).sorted()
    }

    var filteredCards: [FlashCard] {
        var result = currentDeck.cards

        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText) ||
                $0.example.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        switch sortOption {
        case .newest:
            return result.sorted { $0.createdAt > $1.createdAt }
        case .lowestMastery:
            return result.sorted {
                if $0.masteryLevel != $1.masteryLevel {
                    return $0.masteryLevel < $1.masteryLevel
                }
                return $0.createdAt > $1.createdAt
            }
        case .hardest:
            return result.sorted {
                if $0.difficulty.sortOrder != $1.difficulty.sortOrder {
                    return $0.difficulty.sortOrder < $1.difficulty.sortOrder
                }
                return $0.masteryLevel < $1.masteryLevel
            }
        case .alphabetical:
            return result.sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
        }
    }

    var body: some View {
        ZStack {
            Color.mujiBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // ── Deck Header ──
                deckHeader

                // ── Search & Sort Bar ──
                searchAndFilterSection
                    .padding(.horizontal, 18)
                    .padding(.bottom, 10)

                // ── Card List ──
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredCards) { card in
                            CardRowView(
                                card: card,
                                accentColor: accentColor,
                                selectedTag: $selectedTag,
                                onEdit: {
                                    editingCard = card
                                },
                                onDelete: {
                                    cardPendingDelete = card
                                }
                            )
                            .contextMenu {
                                Button {
                                    SpeechManager.shared.speak(card.word, contextText: card.example)
                                } label: {
                                    Label("朗讀發音", systemImage: "speaker.wave.2")
                                }
                                Button {
                                    editingCard = card
                                } label: {
                                    Label("編輯單字", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    cardPendingDelete = card
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                        }

                        if filteredCards.isEmpty {
                            emptyCardsView
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        Haptics.light()
                        showAddCard = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .semibold))
                            Text("單字")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.mujiTextPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(MujiPressableButtonStyle())
                    .touchTarget()

                    if !currentDeck.cards.isEmpty {
                        Button {
                            Haptics.light()
                            showStudy = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("開始學習")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.mujiButtonText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mujiTextPrimary)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(MujiPressableButtonStyle())
                        .touchTarget()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardView(deckId: currentDeck.id)
        }
        .sheet(isPresented: $showEditDeck) {
            EditDeckView(deck: currentDeck)
        }
        .sheet(item: $editingCard) { card in
            EditCardView(deckId: currentDeck.id, card: card)
        }
        .sheet(isPresented: $showStudy) {
            StudyView(deck: currentDeck)
        }
        .alert(
            "確認刪除單字",
            isPresented: Binding(
                get: { cardPendingDelete != nil },
                set: { if !$0 { cardPendingDelete = nil } }
            ),
            presenting: cardPendingDelete
        ) { card in
            Button("刪除", role: .destructive) {
                store.deleteCard(cardId: card.id, fromDeckId: currentDeck.id)
                cardPendingDelete = nil
            }
            Button("取消", role: .cancel) {
                cardPendingDelete = nil
            }
        } message: { card in
            Text("確定要刪除「\(card.word)」嗎？此操作無法還原。")
        }
        .onChange(of: store.decks.contains { $0.id == deck.id }) { exists in
            if !exists {
                dismiss()
            }
        }
    }

    // MARK: - Deck Header
    var deckHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)

                Text(currentDeck.name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.mujiTextPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    showEditDeck = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.mujiTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Circle())
                }
            }

            if !currentDeck.description.isEmpty {
                Text(currentDeck.description)
                    .font(.mujiCallout)
                    .foregroundColor(.mujiTextSecondary)
            }

            // Continuous Progress Bar
            VStack(alignment: .leading, spacing: 5) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mujiSecondarySurface)
                            .frame(height: 5)

                        let ratio = currentDeck.cards.isEmpty ? 0 : CGFloat(currentDeck.masteredCount) / CGFloat(currentDeck.cards.count)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * ratio, height: 5)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text("共 \(currentDeck.cards.count) 張單字")
                        .font(.mujiCaption)
                        .foregroundColor(.mujiTextSecondary)

                    Spacer()

                    Text("已精通 \(currentDeck.masteredCount) 張 (\(String(format: "%.0f", currentDeck.progressPercent))%)")
                        .font(.mujiCaption)
                        .foregroundColor(currentDeck.progressPercent >= 80 ? .mujiSage : .mujiTextSecondary)
                }
            }
        }
        .mujiCard(cornerRadius: 12, padding: 18)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Search & Sort Bar
    var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.mujiTextMuted)

                    TextField("搜尋單字、釋義或例句...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundColor(.mujiTextPrimary)

                    if !searchText.isEmpty {
                        Button {
                            Haptics.light()
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.mujiTextMuted)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Color.mujiCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.mujiBorder, lineWidth: 0.75)
                )

                // Sort Menu
                Menu {
                    ForEach(CardSortOption.allCases, id: \.self) { option in
                        Button {
                            Haptics.selection()
                            sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                        Text(sortOption.rawValue)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.mujiTextSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.mujiCardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.mujiBorder, lineWidth: 0.75)
                    )
                }
            }

            // Tag Filter Chips
            if !allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Button {
                            Haptics.selection()
                            selectedTag = nil
                        } label: {
                            Text("全部")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(selectedTag == nil ? .mujiButtonText : .mujiTextSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(selectedTag == nil ? Color.mujiTextPrimary : Color.mujiCardSurface)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(Color.mujiBorder, lineWidth: selectedTag == nil ? 0 : 0.75)
                                )
                        }
                        .buttonStyle(.plain)

                        ForEach(allTags, id: \.self) { tag in
                            let isSelected = selectedTag == tag
                            Button {
                                Haptics.selection()
                                selectedTag = isSelected ? nil : tag
                            } label: {
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(isSelected ? Color.mujiTextPrimary : Color.mujiCardSurface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().stroke(Color.mujiBorder, lineWidth: isSelected ? 0 : 0.75)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty Cards View
    var emptyCardsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.mujiTextMuted)

            Text(currentDeck.cards.isEmpty ? "尚無單字卡片" : "沒有符合篩選條件的單字")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            if currentDeck.cards.isEmpty {
                Button {
                    showAddCard = true
                } label: {
                    Text("新增第一張單字")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mujiButtonText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.mujiTextPrimary)
                        .clipShape(Capsule())
                }
            } else {
                Button {
                    searchText = ""
                    selectedTag = nil
                } label: {
                    Text("清除搜尋與標籤篩選")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, 50)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Card Row View (Expandable Paper Item)
struct CardRowView: View {
    let card: FlashCard
    let accentColor: Color
    @Binding var selectedTag: String?
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var expanded = false

    var difficultyColor: Color {
        switch card.difficulty {
        case .easy:   return .mujiSage
        case .medium: return .mujiOchre
        case .hard:   return .mujiCrimson
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                // Quick Pronunciation Button
                Button {
                    Haptics.light()
                    SpeechManager.shared.speak(card.word, contextText: card.example)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(accentColor)
                        .frame(width: 30, height: 30)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Circle())
                }
                .buttonStyle(MujiPressableButtonStyle())
                .accessibilityLabel("朗讀 \(card.word)")

                // Expandable Main Area
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        expanded.toggle()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(card.word)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.mujiTextPrimary)

                            Text(card.partOfSpeech.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.mujiTextSecondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.mujiSecondarySurface)
                                .clipShape(Capsule())

                            Text(card.difficulty.localizedLabel)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(difficultyColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(difficultyColor.opacity(0.1))
                                .clipShape(Capsule())

                            Spacer()

                            // Mastery dots
                            HStack(spacing: 3) {
                                ForEach(0..<5, id: \.self) { i in
                                    Circle()
                                        .fill(i < card.masteryLevel ? accentColor : Color.mujiBorder)
                                        .frame(width: 5, height: 5)
                                }
                            }

                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.mujiTextMuted)
                                .padding(.leading, 4)
                        }

                        if !expanded {
                            Text(card.definition)
                                .font(.system(size: 13))
                                .foregroundColor(.mujiTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(MujiCardButtonStyle())
            }

            // Expanded details
            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .fill(Color.mujiBorder)
                        .frame(height: 0.75)
                        .padding(.top, 10)
                        .padding(.bottom, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("中文釋義")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.mujiTextMuted)
                        Text(card.definition)
                            .font(.system(size: 14))
                            .foregroundColor(.mujiTextPrimary)
                    }

                    if !card.example.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("例句")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.mujiTextMuted)

                                Button {
                                    Haptics.light()
                                    SpeechManager.shared.speak(card.example, contextText: card.example, rate: 0.46)
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "speaker.wave.2")
                                            .font(.system(size: 9))
                                        Text("朗讀例句")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundColor(.mujiTextSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.mujiSecondarySurface)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            Text(card.example)
                                .font(.system(size: 13))
                                .foregroundColor(.mujiTextSecondary)
                                .italic()
                        }
                    }

                    if !card.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(card.tags, id: \.self) { tag in
                                Button {
                                    Haptics.selection()
                                    selectedTag = (selectedTag == tag) ? nil : tag
                                } label: {
                                    Text("#\(tag)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedTag == tag ? .mujiButtonText : .mujiTextSecondary)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(selectedTag == tag ? Color.mujiTextPrimary : Color.mujiSecondarySurface)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    HStack {
                        Text("已複習 \(card.reviewCount) 次")
                            .font(.system(size: 11))
                            .foregroundColor(.mujiTextMuted)

                        Spacer()

                        HStack(spacing: 14) {
                            Button {
                                Haptics.light()
                                onEdit()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 11))
                                    Text("編輯")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.mujiTextPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.mujiSecondarySurface)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(MujiPressableButtonStyle())

                            Button {
                                Haptics.warning()
                                onDelete()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 11))
                                    Text("刪除")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.mujiCrimson)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.mujiCrimson.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(MujiPressableButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .mujiCard(cornerRadius: 12, padding: 14)
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck.sampleDeck)
    }
    .environmentObject(DeckStore())
}
