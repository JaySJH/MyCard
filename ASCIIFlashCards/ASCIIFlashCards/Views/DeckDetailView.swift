import SwiftUI

// MARK: - Deck Detail View (MUJI Clean Paper Style)
struct DeckDetailView: View {
    @EnvironmentObject var store: DeckStore
    @State var deck: Deck
    @State private var showAddCard = false
    @State private var showEditDeck = false
    @State private var editingCard: FlashCard? = nil
    @State private var showStudy = false
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss

    var accentColor: Color { Color.terminalColor(for: currentDeck.colorTheme) }

    // Always sync deck from store
    var currentDeck: Deck {
        store.decks.first(where: { $0.id == deck.id }) ?? deck
    }

    var filteredCards: [FlashCard] {
        if searchText.isEmpty { return currentDeck.cards }
        return currentDeck.cards.filter {
            $0.word.localizedCaseInsensitiveContains(searchText) ||
            $0.definition.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        ZStack {
            Color.mujiBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // ── Deck Header ──
                deckHeader

                // ── Search Bar ──
                searchBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                // ── Card List ──
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredCards) { card in
                            CardRowView(
                                card: card,
                                accentColor: accentColor,
                                onEdit: {
                                    editingCard = card
                                },
                                onDelete: {
                                    store.deleteCard(cardId: card.id, fromDeckId: currentDeck.id)
                                }
                            )
                            .contextMenu {
                                Button {
                                    editingCard = card
                                } label: {
                                    Label("編輯單字", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    store.deleteCard(cardId: card.id, fromDeckId: currentDeck.id)
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

                    if !currentDeck.cards.isEmpty {
                        Button {
                            showStudy = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                                Text("開始學習")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.mujiTextPrimary)
                            .clipShape(Capsule())
                        }
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
        .padding(.bottom, 12)
    }

    // MARK: - Search Bar
    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(.mujiTextMuted)

            TextField("搜尋單字或釋義...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(.mujiTextPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.mujiTextMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.mujiCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.mujiBorder, lineWidth: 0.75)
        )
    }

    // MARK: - Empty Cards View
    var emptyCardsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.mujiTextMuted)

            Text("尚無單字卡片")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            Button {
                showAddCard = true
            } label: {
                Text("新增第一張單字")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.mujiTextPrimary)
                    .clipShape(Capsule())
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
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
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
                            .padding(.leading, 6)
                    }

                    if !expanded {
                        Text(card.definition)
                            .font(.system(size: 13))
                            .foregroundColor(.mujiTextSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)

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
                        VStack(alignment: .leading, spacing: 3) {
                            Text("例句")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.mujiTextMuted)
                            Text(card.example)
                                .font(.system(size: 13))
                                .foregroundColor(.mujiTextSecondary)
                                .italic()
                        }
                    }

                    if !card.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(card.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.mujiTextSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.mujiSecondarySurface)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    HStack {
                        Text("已複習 \(card.reviewCount) 次")
                            .font(.system(size: 11))
                            .foregroundColor(.mujiTextMuted)

                        Spacer()

                        HStack(spacing: 12) {
                            Button {
                                onEdit()
                            } label: {
                                Text("編輯")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.mujiTextSecondary)
                            }

                            Button {
                                onDelete()
                            } label: {
                                Text("刪除")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.mujiCrimson)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .mujiCard(cornerRadius: 10, padding: 14)
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck.sampleDeck)
    }
    .environmentObject(DeckStore())
    .preferredColorScheme(.light)
}
