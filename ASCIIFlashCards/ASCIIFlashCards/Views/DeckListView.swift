import SwiftUI

// MARK: - Deck List View (MUJI Stationery Style)
struct DeckListView: View {
    @EnvironmentObject var store: DeckStore
    @State private var showAddDeck = false
    @State private var editingDeck: Deck? = nil
    @State private var searchText = ""

    var filteredDecks: [Deck] {
        if searchText.isEmpty { return store.decks }
        return store.decks.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
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

                    // ── Decks Scroll List ──
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(filteredDecks) { deck in
                                NavigationLink(destination: DeckDetailView(deck: deck)) {
                                    DeckRowView(deck: deck)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        editingDeck = deck
                                    } label: {
                                        Label("編輯字卡庫", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        store.deleteDeck(byId: deck.id)
                                    } label: {
                                        Label("刪除字卡庫", systemImage: "trash")
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
                showAddDeck = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("新增庫")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.mujiTextPrimary)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Search Field
    var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundColor(.mujiTextMuted)

            TextField("搜尋單字庫...", text: $searchText)
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
        .padding(.vertical, 9)
        .background(Color.mujiCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.mujiBorder, lineWidth: 0.75)
        )
    }

    // MARK: - Empty State
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.mujiTextMuted)

            Text("尚無符合的單字庫")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            Button {
                showAddDeck = true
            } label: {
                Text("建立第一組單字庫")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.mujiTextPrimary)
                    .clipShape(Capsule())
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
