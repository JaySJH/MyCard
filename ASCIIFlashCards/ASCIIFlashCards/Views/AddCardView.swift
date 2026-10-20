import SwiftUI

// MARK: - Add Deck View (MUJI Minimal Form)
struct AddDeckView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedTheme: DeckTheme = .green

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header
                        formHeader(title: "新增單字庫", subtitle: "建立專屬的單字學習分類")

                        // Name Field
                        mujiField(label: "單字庫名稱 *", placeholder: "例如：多益核心詞彙、日常會話...", text: $name)

                        // Description
                        mujiField(label: "備註說明", placeholder: "選填，簡要描述此字卡庫內容...", text: $description)

                        // Theme Selector
                        themeSelector

                        // Preview
                        deckPreview

                        // Action Buttons
                        actionButtons
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    var themeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("標籤色調")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            HStack(spacing: 12) {
                ForEach(DeckTheme.allCases, id: \.self) { theme in
                    let color = Color.terminalColor(for: theme)
                    let isSelected = selectedTheme == theme
                    Button {
                        selectedTheme = theme
                    } label: {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 32, height: 32)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var deckPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("預覽效果")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            let accent = Color.terminalColor(for: selectedTheme)
            let displayName = name.isEmpty ? "未命名單字庫" : name

            HStack(spacing: 12) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.mujiTextPrimary)
                    Text("0 張單字")
                        .font(.mujiCaption)
                        .foregroundColor(.mujiTextMuted)
                }
                Spacer()
            }
            .mujiCard(cornerRadius: 10, padding: 14)
        }
    }

    var actionButtons: some View {
        let isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
        return HStack(spacing: 12) {
            Button {
                Haptics.light()
                dismiss()
            } label: {
                Text("取消")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mujiTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.mujiSecondarySurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(MujiPressableButtonStyle())

            Button {
                guard isValid else { return }
                Haptics.success()
                let deck = Deck(
                    name: name.trimmingCharacters(in: .whitespaces),
                    description: description.trimmingCharacters(in: .whitespaces),
                    colorTheme: selectedTheme
                )
                store.addDeck(deck)
                dismiss()
            } label: {
                Text("建立")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mujiButtonText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(isValid ? Color.mujiTextPrimary : Color.mujiTextMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(MujiPressableButtonStyle())
            .disabled(!isValid)
        }
        .padding(.top, 10)
    }
}

// MARK: - Edit Deck View
struct EditDeckView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss

    let deck: Deck

    @State private var name: String
    @State private var description: String
    @State private var selectedTheme: DeckTheme
    @State private var showDeleteConfirm = false

    init(deck: Deck) {
        self.deck = deck
        _name = State(initialValue: deck.name)
        _description = State(initialValue: deck.description)
        _selectedTheme = State(initialValue: deck.colorTheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        formHeader(title: "編輯單字庫", subtitle: "修改庫名稱或色調標籤")

                        mujiField(label: "單字庫名稱 *", placeholder: "請輸入名稱...", text: $name)
                        mujiField(label: "備註說明", placeholder: "選填...", text: $description)

                        // Theme Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("標籤色調")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.mujiTextSecondary)

                            HStack(spacing: 12) {
                                ForEach(DeckTheme.allCases, id: \.self) { theme in
                                    let color = Color.terminalColor(for: theme)
                                    let isSelected = selectedTheme == theme
                                    Button {
                                        selectedTheme = theme
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 32, height: 32)
                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Action Buttons
                        let isValid = !name.trimmingCharacters(in: .whitespaces).isEmpty
                        HStack(spacing: 12) {
                            Button {
                                Haptics.light()
                                dismiss()
                            } label: {
                                Text("取消")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.mujiSecondarySurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())

                            Button {
                                guard isValid else { return }
                                Haptics.success()
                                var updated = deck
                                updated.name = name.trimmingCharacters(in: .whitespaces)
                                updated.description = description.trimmingCharacters(in: .whitespaces)
                                updated.colorTheme = selectedTheme
                                store.updateDeck(updated)
                                dismiss()
                            } label: {
                                Text("儲存變更")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiButtonText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(isValid ? Color.mujiTextPrimary : Color.mujiTextMuted)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())
                            .disabled(!isValid)
                        }

                        Divider()
                            .background(Color.mujiBorder)
                            .padding(.vertical, 6)

                        // Delete
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("刪除此單字庫")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiCrimson)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mujiCrimson.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .alert("確認刪除", isPresented: $showDeleteConfirm) {
                Button("刪除", role: .destructive) {
                    store.deleteDeck(byId: deck.id)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("確定要刪除「\(deck.name)」嗎？庫內的所有單字將一併移除。")
            }
        }
    }
}

// MARK: - Add Card View
struct AddCardView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss

    let deckId: UUID

    @State private var word = ""
    @State private var definition = ""
    @State private var example = ""
    @State private var selectedPOS: PartOfSpeech = .noun
    @State private var selectedDifficulty: Difficulty = .medium
    @State private var tagsInput = ""
    @State private var savedBannerText: String? = nil

    var canSave: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        formHeader(title: "新增單字卡", subtitle: "建立新的詞彙記憶卡（自動支援語音發音）")

                        if let banner = savedBannerText {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(banner)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                            }
                            .foregroundColor(.mujiSage)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.mujiSage.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        mujiField(
                            label: "單字 (Word) *",
                            placeholder: "例如：Ephemeral 或 経験",
                            text: $word,
                            showPronunciationPreview: true,
                            pronunciationContext: example
                        )
                        mujiField(
                            label: "釋義 (Definition) *",
                            placeholder: "例如：短暫的、轉瞬即逝的（支援換行）",
                            text: $definition,
                            isMultiline: true
                        )
                        mujiField(
                            label: "例句 (Example)",
                            placeholder: "例如：Fame in the modern world is ephemeral.",
                            text: $example,
                            isMultiline: true,
                            showPronunciationPreview: true,
                            pronunciationContext: example
                        )

                        // Part of Speech
                        posSection

                        // Difficulty
                        difficultySection

                        // Tags
                        mujiField(label: "標籤 (Tags)", placeholder: "例如：進階, 托福, 哲學 (以逗號分隔)", text: $tagsInput)

                        // Batch Add Button (Save & Add Another)
                        Button {
                            saveCard(dismissAfter: false)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.rectangle.on.rectangle")
                                    .font(.system(size: 13, weight: .medium))
                                Text("儲存並繼續新增下一張")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(canSave ? .mujiTextPrimary : .mujiTextMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Color.mujiCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.mujiBorder, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(MujiPressableButtonStyle())
                        .disabled(!canSave)

                        // Actions
                        HStack(spacing: 12) {
                            Button {
                                Haptics.light()
                                dismiss()
                            } label: {
                                Text("取消")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.mujiSecondarySurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())

                            Button {
                                saveCard(dismissAfter: true)
                            } label: {
                                Text("新增完成")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiButtonText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(canSave ? Color.mujiTextPrimary : Color.mujiTextMuted)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())
                            .disabled(!canSave)
                        }
                        .padding(.top, 2)
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func saveCard(dismissAfter: Bool) {
        guard canSave else { return }
        Haptics.success()
        let savedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let tags = tagsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let card = FlashCard(
            word: savedWord,
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
            example: example.trimmingCharacters(in: .whitespacesAndNewlines),
            partOfSpeech: selectedPOS,
            difficulty: selectedDifficulty,
            tags: tags
        )
        store.addCard(card, toDeckId: deckId)

        if dismissAfter {
            dismiss()
        } else {
            withAnimation {
                word = ""
                definition = ""
                example = ""
                savedBannerText = "已新增「\(savedWord)」，可繼續輸入下一張"
            }
        }
    }

    var posSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("詞性 (Part of Speech)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PartOfSpeech.allCases, id: \.self) { pos in
                        let isSelected = selectedPOS == pos
                        Button {
                            selectedPOS = pos
                        } label: {
                            Text(pos.label)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
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

    var difficultySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("難易度 (Difficulty)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            HStack(spacing: 10) {
                ForEach(Difficulty.allCases, id: \.self) { diff in
                    let isSelected = selectedDifficulty == diff
                    Button {
                        selectedDifficulty = diff
                    } label: {
                        Text(diff.localizedLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.mujiTextPrimary : Color.mujiCardSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.mujiBorder, lineWidth: isSelected ? 0 : 0.75)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Edit Card View
struct EditCardView: View {
    @EnvironmentObject var store: DeckStore
    @Environment(\.dismiss) var dismiss

    let deckId: UUID
    let card: FlashCard

    @State private var word: String
    @State private var definition: String
    @State private var example: String
    @State private var selectedPOS: PartOfSpeech
    @State private var selectedDifficulty: Difficulty
    @State private var tagsInput: String
    @State private var showDeleteConfirm = false

    init(deckId: UUID, card: FlashCard) {
        self.deckId = deckId
        self.card = card
        _word = State(initialValue: card.word)
        _definition = State(initialValue: card.definition)
        _example = State(initialValue: card.example)
        _selectedPOS = State(initialValue: card.partOfSpeech)
        _selectedDifficulty = State(initialValue: card.difficulty)
        _tagsInput = State(initialValue: card.tags.joined(separator: ", "))
    }

    var canSave: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mujiBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        formHeader(title: "編輯單字卡", subtitle: "修改單字、釋義或難度")

                        mujiField(
                            label: "單字 (Word) *",
                            placeholder: "Word",
                            text: $word,
                            showPronunciationPreview: true,
                            pronunciationContext: example
                        )
                        mujiField(
                            label: "釋義 (Definition) *",
                            placeholder: "Definition",
                            text: $definition,
                            isMultiline: true
                        )
                        mujiField(
                            label: "例句 (Example)",
                            placeholder: "Example",
                            text: $example,
                            isMultiline: true,
                            showPronunciationPreview: true,
                            pronunciationContext: example
                        )

                        // POS
                        VStack(alignment: .leading, spacing: 8) {
                            Text("詞性")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.mujiTextSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(PartOfSpeech.allCases, id: \.self) { pos in
                                        let isSelected = selectedPOS == pos
                                        Button {
                                            selectedPOS = pos
                                        } label: {
                                            Text(pos.label)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
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

                        // Difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            Text("難易度")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.mujiTextSecondary)

                            HStack(spacing: 10) {
                                ForEach(Difficulty.allCases, id: \.self) { diff in
                                    let isSelected = selectedDifficulty == diff
                                    Button {
                                        selectedDifficulty = diff
                                    } label: {
                                        Text(diff.localizedLabel)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isSelected ? .mujiButtonText : .mujiTextSecondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color.mujiTextPrimary : Color.mujiCardSurface)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(Color.mujiBorder, lineWidth: isSelected ? 0 : 0.75)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        mujiField(label: "標籤 (Tags)", placeholder: "tag1, tag2...", text: $tagsInput)

                        // Actions
                        HStack(spacing: 12) {
                            Button {
                                Haptics.light()
                                dismiss()
                            } label: {
                                Text("取消")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(Color.mujiSecondarySurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())

                            Button {
                                guard canSave else { return }
                                Haptics.success()
                                let tags = tagsInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                                let updated = card
                                updated.word = word.trimmingCharacters(in: .whitespacesAndNewlines)
                                updated.definition = definition.trimmingCharacters(in: .whitespacesAndNewlines)
                                updated.example = example.trimmingCharacters(in: .whitespacesAndNewlines)
                                updated.partOfSpeech = selectedPOS
                                updated.difficulty = selectedDifficulty
                                updated.tags = tags
                                store.updateCard(updated, inDeckId: deckId)
                                dismiss()
                            } label: {
                                Text("儲存變更")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mujiButtonText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(canSave ? Color.mujiTextPrimary : Color.mujiTextMuted)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(MujiPressableButtonStyle())
                            .disabled(!canSave)
                        }

                        Divider()
                            .background(Color.mujiBorder)
                            .padding(.vertical, 6)

                        // Delete
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("刪除此卡片")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.mujiCrimson)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mujiCrimson.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .alert("確認刪除", isPresented: $showDeleteConfirm) {
                Button("刪除", role: .destructive) {
                    store.deleteCard(cardId: card.id, fromDeckId: deckId)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("確定要刪除「\(card.word)」嗎？此操作無法還原。")
            }
        }
    }
}

// MARK: - Form Helper Views
func formHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.mujiTextPrimary)
        Text(subtitle)
            .font(.mujiCaption)
            .foregroundColor(.mujiTextSecondary)

        Rectangle()
            .fill(Color.mujiBorder)
            .frame(height: 0.75)
            .padding(.top, 6)
    }
}

@MainActor
func mujiField(
    label: String,
    placeholder: String,
    text: Binding<String>,
    isMultiline: Bool = false,
    showPronunciationPreview: Bool = false,
    pronunciationContext: String = ""
) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mujiTextSecondary)

            Spacer()

            if showPronunciationPreview && !text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    Haptics.light()
                    SpeechManager.shared.speak(text.wrappedValue, contextText: pronunciationContext)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 11))
                        Text("試聽發音")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.mujiSlateBlue)
                }
                .buttonStyle(.plain)
            }
        }

        if isMultiline {
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(2...5)
                .font(.system(size: 14))
                .foregroundColor(.mujiTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.mujiCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.mujiBorder, lineWidth: 0.75)
                )
        } else {
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundColor(.mujiTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.mujiCardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.mujiBorder, lineWidth: 0.75)
                )
        }
    }
}

#Preview {
    AddDeckView()
        .environmentObject(DeckStore())
}
