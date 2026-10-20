import SwiftUI

// MARK: - Deck List View (MUJI Stationery Style)
struct DeckListView: View {
    @EnvironmentObject var store: DeckStore
    @State private var showAddDeck = false
    @State private var editingDeck: Deck? = nil
    @State private var deckPendingDelete: Deck? = nil
    @State private var searchText = ""

    var filteredDecks: [Deck] {
        if searchText.isEmpty { return store.decks }
        return store.decks.filter { deck in
            deck.name.localizedCaseInsensitiveContains(searchText) ||
            deck.description.localizedCaseInsensitiveContains(searchText) ||
            deck.cards.contains {
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }

    var globalMatchedCards: [(deck: Deck, card: FlashCard)] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var matches: [(deck: Deck, card: FlashCard)] = []
        for deck in store.decks {
            for card in deck.cards {
                if card.word.localizedCaseInsensitiveContains(query) ||
                   card.definition.localizedCaseInsensitiveContains(query) ||
                   card.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) {
                    matches.append((deck: deck, card: card))
                }
            }
        }
        return matches
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    // ── Header ──
                    libraryHeader

                    // ── Search Field ──
                    searchField
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)

                    // ── Decks & Global Cards Scroll List ──
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(filteredDecks) { deck in
                                NavigationLink(destination: DeckDetailView(deck: deck)) {
                                    DeckRowView(deck: deck)
                                }
                                .buttonStyle(MujiCardButtonStyle())
                                .contextMenu {
                                    Button {
                                        editingDeck = deck
                                    } label: {
                                        Label("編輯字卡庫", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        deckPendingDelete = deck
                                    } label: {
                                        Label("刪除字卡庫", systemImage: "trash")
                                    }
                                }
                            }

                            // Global Word Matches Section when searching
                            if !globalMatchedCards.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("符合的單字 (\(globalMatchedCards.count))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.mujiTextSecondary)
                                        .padding(.top, 8)

                                    ForEach(globalMatchedCards, id: \.card.id) { item in
                                        NavigationLink(destination: DeckDetailView(deck: item.deck)) {
                                            HStack(spacing: 10) {
                                                Button {
                                                    Haptics.light()
                                                    SpeechManager.shared.speak(item.card.word, contextText: item.card.example)
                                                } label: {
                                                    Image(systemName: "speaker.wave.2.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(Color.terminalColor(for: item.deck.colorTheme))
                                                        .frame(width: 28, height: 28)
                                                        .background(Color.mujiSecondarySurface)
                                                        .clipShape(Circle())
                                                }
                                                .buttonStyle(.plain)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack(spacing: 6) {
                                                        Text(item.card.word)
                                                            .font(.system(size: 15, weight: .medium))
                                                            .foregroundColor(.mujiTextPrimary)
                                                        Text(item.card.partOfSpeech.label)
                                                            .font(.system(size: 10, weight: .medium))
                                                            .foregroundColor(.mujiTextSecondary)
                                                            .padding(.horizontal, 5)
                                                            .padding(.vertical, 1.5)
                                                            .background(Color.mujiSecondarySurface)
                                                            .clipShape(Capsule())
                                                    }
                                                    Text(item.card.definition)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.mujiTextSecondary)
                                                        .lineLimit(1)
                                                }

                                                Spacer()

                                                Text(item.deck.name)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.mujiTextMuted)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color.mujiSecondarySurface)
                                                    .clipShape(Capsule())
                                            }
                                            .mujiCard(cornerRadius: 10, padding: 12)
                                        }
                                        .buttonStyle(MujiCardButtonStyle())
                                    }
                                }
                            }

                            if filteredDecks.isEmpty {
                                emptyState
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddDeck) {
                AddDeckView()
            }
            .sheet(item: $editingDeck) { deck in
                EditDeckView(deck: deck)
            }
            .alert(
                "確認刪除單字庫",
                isPresented: Binding(
                    get: { deckPendingDelete != nil },
                    set: { if !$0 { deckPendingDelete = nil } }
                ),
                presenting: deckPendingDelete
            ) { deck in
                Button("刪除", role: .destructive) {
                    store.deleteDeck(byId: deck.id)
                    deckPendingDelete = nil
                }
                Button("取消", role: .cancel) {
                    deckPendingDelete = nil
                }
            } message: { deck in
                Text("確定要刪除「\(deck.name)」嗎？庫內的 \(deck.cards.count) 張單字將一併移除。")
            }
        }
    }

    // MARK: - Library Header
    var libraryHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("所有字卡庫")
                    .font(.mujiCaption)
                    .foregroundColor(.mujiTextSecondary)
                HStack(spacing: 6) {
                    Text("單字庫")
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(.mujiTextPrimary)
                    Text("\(store.decks.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mujiTextMuted)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.mujiSecondarySurface)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Button {
                Haptics.light()
                showAddDeck = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("建立單字庫")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.mujiButtonText)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.mujiTextPrimary)
                .clipShape(Capsule())
            }
            .buttonStyle(MujiPressableButtonStyle())
            .touchTarget()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Search Field
    var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.mujiTextMuted)

            TextField("搜尋單字庫、單字或中文釋義...", text: $searchText)
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
                .touchTarget()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.mujiCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.mujiBorder, lineWidth: 0.75)
        )
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.mujiTextMuted)

            Text(store.decks.isEmpty ? "尚無單字庫" : "尚無符合搜尋的單字庫或單字")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            HStack(spacing: 10) {
                Button {
                    showAddDeck = true
                } label: {
                    Text("建立單字庫")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mujiButtonText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.mujiTextPrimary)
                        .clipShape(Capsule())
                }

                if store.decks.isEmpty {
                    Button {
                        Haptics.light()
                        store.restoreSampleDecks()
                    } label: {
                        Text("載入範例字卡庫")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.mujiTextPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.mujiSecondarySurface)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Deck Row View
struct DeckRowView: View {
    let deck: Deck
    @EnvironmentObject var store: DeckStore

    var accentColor: Color {
        Color.terminalColor(for: deck.colorTheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row
            HStack(alignment: .center) {
                // Color badge dot
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)

                Text(deck.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mujiTextPrimary)

                Spacer()

                Text("\(deck.cards.count) 張")
                    .font(.mujiCaption)
                    .foregroundColor(.mujiTextSecondary)
            }

            if !deck.description.isEmpty {
                Text(deck.description)
                    .font(.mujiCallout)
                    .foregroundColor(.mujiTextSecondary)
                    .lineLimit(1)
            }

            // Continuous Progress Bar
            VStack(alignment: .leading, spacing: 5) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mujiSecondarySurface)
                            .frame(height: 4)

                        let ratio = deck.cards.isEmpty ? 0 : CGFloat(deck.masteredCount) / CGFloat(deck.cards.count)
                        Capsule()
                            .fill(accentColor)
                            .frame(width: geo.size.width * ratio, height: 4)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text("掌握度 \(String(format: "%.0f", deck.progressPercent))%")
                        .font(.system(size: 11))
                        .foregroundColor(.mujiTextMuted)

                    Spacer()

                    Text("已精通 \(deck.masteredCount) 張")
                        .font(.system(size: 11))
                        .foregroundColor(.mujiTextMuted)
                }
            }
        }
        .mujiCard(cornerRadius: 12, padding: 16)
    }
}

#Preview {
    DeckListView()
        .environmentObject(DeckStore())
        .preferredColorScheme(.light)
}
