import SwiftUI

// MARK: - Stats View (MUJI Data & Analytics Style)
struct StatsView: View {
    @EnvironmentObject var store: DeckStore
    @State private var selectedLevel: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // ── Header ──
                        statsHeader

                        // ── Overview Card ──
                        overviewCard

                        // ── Mastery Bar Chart ──
                        masteryDistributionCard

                        // ── Deck Breakdown ──
                        deckBreakdownCard

                        // ── Achievements ──
                        achievementsCard

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Stats Header
    var statsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("學習成果")
                .font(.mujiCaption)
                .foregroundColor(.mujiTextSecondary)

            Text("學習統計")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(.mujiTextPrimary)

            Rectangle()
                .fill(Color.mujiBorder)
                .frame(height: 0.75)
                .padding(.top, 6)
        }
    }

    // MARK: - Overview Card
    var overviewCard: some View {
        let stats = store.studyStats
        return VStack(alignment: .leading, spacing: 16) {
            Text("總覽數據")
                .font(.mujiHeadline)
                .foregroundColor(.mujiTextPrimary)

            // Grid of key stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                metricBox(title: "單字庫", value: "\(store.decks.count)")
                metricBox(title: "總單字卡", value: "\(store.totalCards)")
                metricBox(title: "已精通單字", value: "\(store.totalMastered)")

                metricBox(title: "複習次數", value: "\(stats.totalReviews)")
                metricBox(title: "答對次數", value: "\(stats.correctCount)", color: .mujiSage)
                metricBox(title: "加強次數", value: "\(stats.incorrectCount)", color: .mujiCrimson)
            }

            Rectangle()
                .fill(Color.mujiBorder)
                .frame(height: 0.75)
                .padding(.vertical, 2)

            // Accuracy & Progress
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("整體掌握度")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mujiTextSecondary)
                    Spacer()
                    Text("\(String(format: "%.0f", store.overallProgress))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mujiTextPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.mujiSecondarySurface)
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.mujiCrimson)
                            .frame(width: geo.size.width * CGFloat(store.overallProgress / 100), height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("複習正確率")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mujiTextSecondary)
                    Spacer()
                    Text("\(String(format: "%.1f", stats.accuracy))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mujiSage)
                }
            }
        }
        .mujiCard(cornerRadius: 12, padding: 18)
    }

    func metricBox(title: String, value: String, color: Color = .mujiTextPrimary) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.mujiTextMuted)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mastery Distribution Card (Native Smooth Bar Chart)
    var masteryDistributionCard: some View {
        let levels = (0...5).map { level in
            store.decks.flatMap { $0.cards }.filter { $0.masteryLevel == level }.count
        }
        let maxCount = max(levels.max() ?? 1, 1)
        let levelLabels = ["新單字", "初識", "進步中", "熟悉", "熟練", "精通"]

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("掌握度分佈")
                    .font(.mujiHeadline)
                    .foregroundColor(.mujiTextPrimary)
                Spacer()
                Text("輕點長條查看詳細")
                    .font(.mujiCaption)
                    .foregroundColor(.mujiTextMuted)
            }

            // Interactive accessible bars (Apple HIG Charts & Accessibility)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0...5, id: \.self) { level in
                    let count = levels[level]
                    let isSelected = selectedLevel == level
                    let barHeight = CGFloat(count) / CGFloat(maxCount) * 80.0

                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selectedLevel = (selectedLevel == level) ? nil : level
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("\(count)")
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .mujiCrimson : .mujiTextMuted)

                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(level >= 4 ? Color.mujiSage : (level >= 2 ? Color.mujiOchre : Color.mujiSecondarySurface))
                                .frame(height: max(barHeight, 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .stroke(isSelected ? Color.mujiCrimson : Color.clear, lineWidth: 2)
                                )
                                .scaleEffect(isSelected ? 1.05 : 1.0, anchor: .bottom)

                            Text("Lv.\(level)")
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .mujiTextPrimary : .mujiTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("等級 \(level)（\(levelLabels[level])），共 \(count) 張單字")
                    .accessibilityHint("點選查看此等級詳細比例")
                }
            }
            .frame(height: 124)
            .padding(.top, 4)

            // Dynamic detail card on selection
            if let level = selectedLevel {
                let count = levels[level]
                let total = store.totalCards
                let percent = total > 0 ? (Double(count) / Double(total) * 100) : 0
                HStack(spacing: 8) {
                    Circle()
                        .fill(level >= 4 ? Color.mujiSage : (level >= 2 ? Color.mujiOchre : Color.mujiSecondarySurface))
                        .frame(width: 8, height: 8)
                    Text("等級 \(level)（\(levelLabels[level])）")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.mujiTextPrimary)
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.mujiBorder)
                    Text("\(count) 張單字（佔比 \(String(format: "%.1f", percent))%）")
                        .font(.system(size: 12))
                        .foregroundColor(.mujiTextSecondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.mujiSecondarySurface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                HStack {
                    Text("Lv.0: 新單字")
                    Spacer()
                    Text("Lv.3: 熟悉")
                    Spacer()
                    Text("Lv.5: 精通")
                }
                .font(.system(size: 10))
                .foregroundColor(.mujiTextMuted)
            }
        }
        .mujiCard(cornerRadius: 14, padding: 18)
    }

    // MARK: - Deck Breakdown Card
    var deckBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("單字庫掌握狀況")
                .font(.mujiHeadline)
                .foregroundColor(.mujiTextPrimary)

            ForEach(store.decks) { deck in
                let accent = Color.terminalColor(for: deck.colorTheme)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                        Text(deck.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiTextPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text("\(deck.masteredCount) / \(deck.cards.count) 張")
                            .font(.system(size: 12))
                            .foregroundColor(.mujiTextSecondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.mujiSecondarySurface)
                                .frame(height: 4)

                            let ratio = deck.cards.isEmpty ? 0 : CGFloat(deck.masteredCount) / CGFloat(deck.cards.count)
                            Capsule()
                                .fill(accent)
                                .frame(width: geo.size.width * ratio, height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding(.vertical, 2)
            }
        }
        .mujiCard(cornerRadius: 12, padding: 18)
    }

    // MARK: - Achievements Card
    var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("學習成就")
                .font(.mujiHeadline)
                .foregroundColor(.mujiTextPrimary)

            let achievements: [(title: String, desc: String, unlocked: Bool)] = [
                ("初試啼聲", "完成首次單字複習", store.studyStats.totalReviews >= 1),
                ("持之以恆", "累計複習超過 10 次", store.studyStats.totalReviews >= 10),
                ("熟能生巧", "累計複習超過 50 次", store.studyStats.totalReviews >= 50),
                ("精通起步", "成功精通第 1 個單字", store.totalMastered >= 1),
                ("詞彙達人", "成功精通 5 個單字", store.totalMastered >= 5),
                ("多元庫藏", "建立 2 個以上的單字庫", store.decks.count >= 2),
                ("詞彙庫收藏家", "累積建檔 20 個以上單字", store.totalCards >= 20)
            ]

            VStack(spacing: 10) {
                ForEach(achievements, id: \.title) { ach in
                    HStack(spacing: 12) {
                        Image(systemName: ach.unlocked ? "rosette" : "circle.dotted")
                            .font(.system(size: 16))
                            .foregroundColor(ach.unlocked ? .mujiOchre : .mujiTextMuted)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(ach.title)
                                .font(.system(size: 14, weight: ach.unlocked ? .medium : .regular))
                                .foregroundColor(ach.unlocked ? .mujiTextPrimary : .mujiTextMuted)
                            Text(ach.desc)
                                .font(.system(size: 11))
                                .foregroundColor(.mujiTextMuted)
                        }

                        Spacer()

                        Text(ach.unlocked ? "已解鎖" : "未解鎖")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(ach.unlocked ? .mujiSage : .mujiTextMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(ach.unlocked ? Color.mujiSage.opacity(0.1) : Color.mujiSecondarySurface)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .mujiCard(cornerRadius: 12, padding: 18)
    }
}

#Preview {
    StatsView()
        .environmentObject(DeckStore())
        .preferredColorScheme(.light)
}
