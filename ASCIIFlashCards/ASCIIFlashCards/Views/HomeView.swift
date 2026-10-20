import SwiftUI

// MARK: - Home View (MUJI Minimalist Style)
struct HomeView: View {
    @EnvironmentObject var store: DeckStore
    @State private var selectedDeckForStudy: Deck? = nil

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // ── Minimalist Header ──
                        headerSection

                        // ── Daily Learning Focus Card ──
                        dailyFocusCard

                        // ── Quick Study Section ──
                        quickStudySection

                        // ── Study Note / Tip ──
//                        studyNoteCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedDeckForStudy) { deck in
                StudyView(deck: deck)
            }
        }
    }

    // MARK: - Header Section
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.mujiCaption)
                        .foregroundColor(.mujiTextSecondary)
                    Text("今日學習")
                        .font(.system(size: 26, weight: .light, design: .default))
                        .foregroundColor(.mujiTextPrimary)
                }

                Spacer()

                if store.studyStats.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                        Text("連續 \(store.studyStats.currentStreak) 天")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.mujiOchre)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.mujiOchre.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Minimalist MUJI Tag
//                Text("FLASHCARDS")
//                    .font(.system(size: 10, weight: .medium, design: .default))
//                    .tracking(1.5)
//                    .foregroundColor(.mujiCrimson)
//                    .padding(.horizontal, 10)
//                    .padding(.vertical, 4)
//                    .background(Color.mujiCrimson.opacity(0.08))
//                    .clipShape(Capsule())
            }

            Rectangle()
                .fill(Color.mujiBorder)
                .frame(height: 0.75)
                .padding(.top, 6)
        }
    }

    // MARK: - Daily Focus Card
    var dailyFocusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("學習進度")
                    .font(.mujiHeadline)
                    .foregroundColor(.mujiTextPrimary)
                Spacer()
                Text("\(store.totalMastered) / \(store.totalCards) 張")
                    .font(.mujiCallout)
                    .foregroundColor(.mujiTextSecondary)
            }

            // Smooth Native Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.mujiSecondarySurface)
                        .frame(height: 6)

                    let ratio = store.totalCards > 0 ? CGFloat(store.totalMastered) / CGFloat(store.totalCards) : 0
                    Capsule()
                        .fill(Color.mujiCrimson)
                        .frame(width: max(0, min(geo.size.width * ratio, geo.size.width)), height: 6)
                }
            }
            .frame(height: 6)

            // Metrics Grid
            HStack(spacing: 0) {
                metricColumn(title: "單字庫", value: "\(store.decks.count)")
                Divider()
                    .frame(height: 28)
                    .background(Color.mujiBorder)
                metricColumn(title: "總卡片數", value: "\(store.totalCards)")
                Divider()
                    .frame(height: 28)
                    .background(Color.mujiBorder)
                metricColumn(title: "掌握率", value: "\(String(format: "%.0f", store.overallProgress))%")
                Divider()
                    .frame(height: 28)
                    .background(Color.mujiBorder)
                metricColumn(title: "正確率", value: "\(String(format: "%.0f", store.studyStats.accuracy))%")
            }
            .padding(.top, 4)
        }
        .mujiCard(cornerRadius: 12, padding: 18)
    }

    func metricColumn(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.mujiTextPrimary)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.mujiTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Study Section
    var quickStudySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("快速複習")
                    .font(.mujiHeadline)
                    .foregroundColor(.mujiTextPrimary)
//                Spacer()
//                Text("點選立即開始")
//                    .font(.mujiCaption)
//                    .foregroundColor(.mujiTextMuted)
            }

            ForEach(store.decks.prefix(3)) { deck in
                quickStudyCard(deck: deck)
            }
        }
    }

    func quickStudyCard(deck: Deck) -> some View {
        let accent = Color.terminalColor(for: deck.colorTheme)

        return Button {
            Haptics.light()
            selectedDeckForStudy = deck
        } label: {
            HStack(spacing: 14) {
                // Subtle colored vertical bar indicating deck theme
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 3.5, height: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        Text("\(deck.cards.count) 張單字")
                            .font(.mujiCaption)
                            .foregroundColor(.mujiTextSecondary)

                        Text("•")
                            .font(.mujiCaption)
                            .foregroundColor(.mujiBorder)

                        Text("已掌握 \(String(format: "%.0f", deck.progressPercent))%")
                            .font(.mujiCaption)
                            .foregroundColor(deck.progressPercent >= 80 ? .mujiSage : .mujiTextSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.mujiTextMuted)
            }
            .mujiCard(cornerRadius: 12, padding: 14)
        }
        .buttonStyle(MujiCardButtonStyle())
    }

    // MARK: - Study Note / Quote Card
//    var studyNoteCard: some View {
//        let tips = [
//            "每天規律複習數個單字，記憶最為深刻長久。",
//            "複習時嘗試在腦中浮現單字拼法與例句場景。",
//            "將學到的單字嘗試組成簡單句子，加深連結。",
//            "依主題分類單字群組，學習效率自然提升。",
//            "重複間隔記憶法（Spaced Repetition）是最高效的學習之道。"
//        ]
//        let tip = tips[Calendar.current.component(.day, from: Date()) % tips.count]
//
//        return HStack(alignment: .top, spacing: 12) {
//            Image(systemName: "quote.opening")
//                .font(.system(size: 14))
//                .foregroundColor(.mujiOchre)
//                .padding(.top, 2)
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("學習筆記")
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundColor(.mujiOchre)
//                Text(tip)
//                    .font(.system(size: 13, weight: .regular))
//                    .foregroundColor(.mujiTextSecondary)
//                    .lineSpacing(3)
//            }
//        }
//        .padding(14)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color.mujiSecondarySurface.opacity(0.6))
//        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
//        .overlay(
//            RoundedRectangle(cornerRadius: 10, style: .continuous)
//                .stroke(Color.mujiBorder.opacity(0.8), lineWidth: 0.75)
//        )
//    }
}

#Preview {
    HomeView()
        .environmentObject(DeckStore())
        .preferredColorScheme(.light)
}
