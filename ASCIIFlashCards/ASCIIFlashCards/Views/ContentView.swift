import SwiftUI

// MARK: - Content View (MUJI Style Tab Bar)
struct ContentView: View {
    @EnvironmentObject var store: DeckStore
    @State private var selectedTab: Int = 0

    init() {
        // Configure translucent tab bar appearance with subtle blur (Apple HIG)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color.mujiBackground).withAlphaComponent(0.85)
        appearance.shadowColor = UIColor(Color.mujiBorder)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    @State private var testSheet: TestSheet? = nil

    enum TestSheet: Identifiable {
        case study
        case addCard
        var id: Int { hashValue }
    }

    var body: some View {
        ZStack {
            Color.mujiBackground.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("首頁", systemImage: selectedTab == 0 ? "house.fill" : "house")
                    }
                    .tag(0)

                DeckListView()
                    .tabItem {
                        Label("單字庫", systemImage: selectedTab == 1 ? "rectangle.stack.fill" : "rectangle.stack")
                    }
                    .tag(1)

                StatsView()
                    .tabItem {
                        Label("學習統計", systemImage: selectedTab == 2 ? "chart.bar.xaxis" : "chart.bar")
                    }
                    .tag(2)
            }
            .tint(.mujiCrimson)
            .onChange(of: selectedTab) { _ in
                Haptics.selection()
            }
            .onAppear {
                if CommandLine.arguments.contains("-UITest_Empty") {
                    selectedTab = 1
                } else if CommandLine.arguments.contains("-UITest_StudyFront") || CommandLine.arguments.contains("-UITest_StudyFinished") || CommandLine.arguments.contains("-UITest_SettingsToggle") {
                    testSheet = .study
                } else if CommandLine.arguments.contains("-UITest_AddCard") {
                    testSheet = .addCard
                } else if CommandLine.arguments.contains("-UITest_ReopenPersistence") {
                    selectedTab = 0
                    if store.decks.isEmpty {
                        store.restoreSampleDecks()
                    }
                    store.studyStats.currentStreak = 1
                    store.studyStats.totalReviews = 8
                    store.studyStats.correctCount = 6
                    store.studyStats.incorrectCount = 2
                }
            }
            .sheet(item: $testSheet) { item in
                switch item {
                case .study:
                    StudyView(deck: store.decks.first ?? Deck.sampleDeck)
                case .addCard:
                    AddCardView(deckId: store.decks.first?.id ?? UUID())
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DeckStore())
}
