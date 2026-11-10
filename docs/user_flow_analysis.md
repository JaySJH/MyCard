# MyCard 核心使用流程與關鍵畫面狀態分析報告

本報告針對 MyCard (ASCIIFlashCards) iOS 單字卡 App，從 App 入口開始追蹤核心使用流程、導覽結構、資料狀態與持久化機制，並定義六大關鍵畫面狀態與驗證指引。

---

## 一、專案版本資訊與核心定位

* **Git 分支**：`main`（分析基準點）
* **最新 Commit**：`32a9213b62aedb884d0758a50c84f090d68b64bc`
* **Commit 說明**：`feat(v1.1): 導入自動語音發音系統與全面優化翻卡及字卡管理使用者體驗`
* **核心使用者**：
  * 需要高頻率背誦單字並依賴主動回想（Active Recall）與間隔重複（Spaced Repetition）的語言學習者（如英文、日語、多益/托福、檢定考生）。
  * 偏好無干擾、MUJI 無印良品風極簡溫潤紙質排版與自然語音朗讀輔助的學習者。
* **核心任務**：
  * **單字庫管理**：分類建立單字庫（Deck）與新增/維護單字卡片（FlashCard）。
  * **翻卡記憶學習**：以單字卡片模式進行主動回想測試、聆聽多語系語音發音、查看語境挖空提示、評估記憶掌握程度。
  * **學習進度追蹤**：掌握熟練度等級（Mastery Level 0~5）、答對率與連續學習天數（Streak）。

---

## 二、使用流程追蹤：入口 → 導覽 → View → 狀態／設定 → 資料來源

以 App 最核心的**「挑選字卡庫進入翻卡學習至完成結算」**流程進行追蹤：

```
[ASCIIFlashCardsApp]
        ↓
  [ContentView] (TabView)
        ↓
   [HomeView] / [DeckListView]
        ↓
  [DeckDetailView] (清單與開始按鈕)
        ↓
    [StudyView] (翻卡、發音、評估、提示、結算)
        ↓
[DeckStore] / [SpeechManager] / [SwiftData]
```

### 1. App 入口 (Entry Point)
* **檔案**：`ASCIIFlashCards/ASCIIFlashCards/ASCIIFlashCardsApp.swift`
* **符號**：`struct ASCIIFlashCardsApp: App`
* **實作細節**：
  * 初始化 SwiftData 的 `ModelContainer`（包含 `Deck`、`FlashCard`、`StudyStatsRecord` 三個 Schema）。
  * 實例化 `@StateObject private var deckStore: DeckStore`。
  * 透過 `.environmentObject(deckStore)` 與 `.modelContainer(container)` 將狀態注入全域視圖樹。

### 2. 導覽層 (Navigation)
* **檔案**：`ASCIIFlashCards/ASCIIFlashCards/Views/ContentView.swift`
* **符號**：`struct ContentView: View`
* **實作細節**：
  * 採用三頁籤 `TabView(selection: $selectedTab)`：
    * `Tab 0`：`HomeView()`（首頁，提供今日學習、掌握率進度條、快速複習入口）。
    * `Tab 1`：`DeckListView()`（單字庫總覽，提供全域搜尋、字卡庫管理）。
    * `Tab 2`：`StatsView()`（學習統計與精通度分佈）。
  * 內部次層導覽：
    * `DeckListView` 使用 `NavigationLink(destination: DeckDetailView(deck: deck))` 推入 `DeckDetailView`。
    * `DeckDetailView` 與 `HomeView` 皆透過 `.sheet` 彈出全螢幕翻卡模態視圖 `StudyView`。

### 3. 核心視圖層 (View)
* **主要視圖**：
  * `DeckListView`：字卡庫清單。
  * `DeckDetailView`：單字庫詳情頁，含頂部統計、排序、標籤篩選與「開始學習」按鈕。
  * `StudyView`：翻卡學習核心視圖。
* **核心子元件**：
  * `DeckDetailView.deckHeader`：顯示目前庫名稱、主題色、卡片總數與掌握度進度條。
  * `StudyView.sessionHeader`：顯示當前單字進度序號、答對/答錯即時統計、上一步（Undo）按鈕、自動發音開關、關閉按鈕與頂部連續進度條。
  * `StudyView.paperFlashCard`：紙質卡片元件，支援 3D 翻轉效果（`cardFront` / `cardBack`）與左右滑動評估手勢。
  * `StudyView.evaluationButtons`：翻面後底部「還不熟」與「已記住」雙按鍵。
  * `StudyView.finishedView`：結算成果面板，含正確率、錯題重新練習與完成退出。

### 4. 狀態／設定層 (State & Settings)
* **全域狀態**：
  * `DeckStore.swift`：`@Published var decks: [Deck]`、`@Published var studyStats: StudyStats`。
* **視圖區域狀態**：
  * `StudyView`：`currentIndex`、`isFlipped`、`sessionCorrect`、`sessionIncorrect`、`studyCards`、`missedCards`、`reviewHistory`、`isFinished`、`flipDegree`、`showHint`。
* **使用者設定**：
  * `SpeechManager.shared`：`@AppStorage("autoPlayPronunciation") var autoPlayOnStudy: Bool`，可跨 Session 記憶使用者是否啟用進卡自動朗讀。
  * 學習範圍設定：`studyScope: StudyScope`（`.all` 或 `.unmastered`）。

### 5. 資料來源 (Data Source)
* **本地資料庫**：SwiftData（iOS 17+），儲存於 SQLite 底層，操作透過 `ModelContext`（`modelContext.insert`、`modelContext.delete`、`modelContext.save()`）。
* **初始預設種子資料**：
  * `DeckStore.swift` 首次執行以 `hasSeededKey` 控制載入 `Deck.sampleDeck`（8 張英文卡）與 `Deck.japaneseVocabDeck`（3 張日文卡）。

---

## 三、核心流程 Happy Path

> **流程名稱**：單字庫翻卡複習與結算流程（Flashcard Study Flow）

1. **起始條件 (Pre-conditions)**：
   * App 已啟動並停留在首頁或「單字庫」頁籤。
   * 資料庫內至少存在一個包含大於等於 1 張單字卡的單字庫（例如內建的「English Vocabulary」）。
2. **使用者操作 (User Actions)**：
   * 點選「單字庫」頁籤中的「English Vocabulary」卡片進入字卡詳情頁（`DeckDetailView`）。
   * 點選右上角的「開始學習」按鈕（或於首頁點擊快速複習卡）。
   * 在彈出的 `StudyView` 視圖中看卡片正面，可點擊「發音」聽單字朗讀，或點擊「燈泡」按鈕查看挖空線索。
   * 輕點卡片中央或點擊底部「查看釋義」按鈕將卡片翻轉至背面。
   * 依據自身記憶狀況，點擊「已記住」（或向右滑動卡片）評估為正確；或點擊「還不熟」（或向左滑動卡片）評估為加強。
   * 連續完成該字卡庫內所有卡片評估。
   * 在最後出現的「本次學習完成」成果面板中，點擊「完成學習」。
3. **預期畫面 (Expected UI / Screens)**：
   * 進入 `StudyView`：頂部顯示庫名稱「English Vocabulary」、卡片序號「1 / 8」、進度條與自動發音圖示；中間為白底圓角紙質卡片顯示大字型單字、詞性、難度與熟練度小圓點。
   * 翻面動畫：卡片進行 180 度平滑 3D 旋轉，正面文字隱藏，背面展示中文釋義、例句與朗讀例句按鈕；底部按鈕切換為「還不熟」（紅框）與「已記住」（綠底）。
   * 結算畫面：出現綠色打勾圖示、「本次學習完成」、顯示「正確率 XX%」進度條、已掌握張數與需再加強張數。
   * 點擊「完成學習」後，模態視窗關閉，回到 `DeckDetailView`，上方掌握度百分比與卡片掌握小圓點已即時同步更新。
4. **成功條件 (Success Criteria / Post-conditions)**：
   * 被評為「已記住」的卡片其 `masteryLevel` 數值加 1（上限 5），`reviewCount` 加 1；評為「還不熟」則 `masteryLevel` 減 1（下限 0）。
   * `StudyStatsRecord` 內的 `totalReviews` 正確累計、`lastStudied` 更新為當前時間、`currentStreak` 依日期邏輯推進。
   * 變更經由 `modelContext.save()` 成功寫入 SwiftData，重開 App 數據不遺失。

---

## 四、六大關鍵畫面狀態分析

### 狀態 1：空白狀態（字卡庫完全為空或搜尋無結果）
* **說明**：當使用者刪除所有字卡庫、尚未建立任何字卡庫，或是搜尋關鍵字查無結果時的畫面狀態。
* **標示**：`[從原始碼確認]`
* **測試資料**：
  * 情況 A：清空資料庫所有字卡庫。
  * 情況 B：在搜尋欄輸入無效關鍵字，例如 `"xyznonexistent999"`。
* **進入步驟**：
  1. 切換至「單字庫」頁籤（`DeckListView`）。
  2. 在上方搜尋欄點擊並輸入 `"xyznonexistent999"`。
* **預期結果**：
  * 列表區域顯示 `Image(systemName: "tray")` 紙匣圖示。
  * 提示文字顯示「尚無符合搜尋的單字庫或單字」（若是完全無字卡庫則顯示「尚無單字庫」）。
  * 畫面中央顯示「建立單字庫」膠囊按鈕；若庫全空時還會出現「載入範例字卡庫」按鈕。
* **如何還原**：點擊搜尋欄右側的 `xmark.circle.fill` 按鈕清除文字，即刻恢復顯示所有字卡庫。
* **截圖檔名**：`01_empty_state_search.png`

---

### 狀態 2：有資料狀態（翻卡學習正面一般狀態）
* **說明**：進入翻卡學習時，展示第一張單字卡正面的標準學習介面。
* **標示**：`[從原始碼確認]`
* **測試資料**：內建字卡庫「English Vocabulary」內的第一張單字卡（如 `word: "ephemeral"`, `partOfSpeech: .adjective`, `difficulty: .hard`）。
* **進入步驟**：
  1. 於「單字庫」頁籤點選「English Vocabulary」。
  2. 點擊右上角「開始學習」膠囊按鈕。
* **預期結果**：
  * 頂部標頭顯示「English Vocabulary」、序號「1 / 8」。
  * 卡片頂部呈現 `ADJ` 標籤、`挑戰` 難度標籤與 2 顆綠色熟練度實心圓點（3 顆空心圓點）。
  * 卡片中央呈現大字「ephemeral」，下方有「發音」按鈕。
  * 底部按鈕顯示黑色全寬「查看釋義」按鈕與右側黃色「燈泡提示」按鈕。
* **如何還原**：點擊右上角「✕」按鈕直接離開學習模式回到詳情頁。
* **截圖檔名**：`02_study_active_front.png`

---

### 狀態 3：輸入錯誤／防呆驗證狀態（建立單字時未填必填欄位）
* **說明**：在新增單字卡（`AddCardView`）時，單字與釋義為必填，驗證未通過時停用儲存按鈕的防呆狀態。
* **標示**：`[從原始碼確認]`
* **測試資料**：
  * 單字欄位留白，或僅輸入半形空白 `"   "`。
  * 釋義欄位留白。
* **進入步驟**：
  1. 進入任一單字庫詳情頁（`DeckDetailView`）。
  2. 點擊右上角「＋ 單字」按鈕彈出 `AddCardView`。
  3. 單字欄位保持空白，僅在例句欄位輸入 `"This is an example."`。
* **預期結果**：
  * `canSave` 計算為 `false`。
  * 中段的「儲存並繼續新增下一張」按鈕字體反灰（`Color.mujiTextMuted`），處於不可點擊（`disabled(true)`）狀態。
  * 底部的「新增完成」主按鈕背景呈現淺灰色（`Color.mujiTextMuted`），點擊無任何反應、不會發出 Haptic 反饋，杜絕空單字寫入資料庫。
* **如何還原**：點擊左下方「取消」按鈕退出表單，或於「單字」與「釋義」欄位填入有效文字即可解除停用狀態。
* **截圖檔名**：`03_add_card_validation_disabled.png`

---

### 狀態 4：完成後狀態（學習成果結算畫面）
* **說明**：翻卡學習 Session 完成所有卡片評估後，觸發的最終結算儀表板。
* **標示**：`[從原始碼確認]`
* **測試資料**：於 8 張單字卡的 Session 中，評估 6 張「已記住」、2 張「還不熟」。
* **進入步驟**：
  1. 在 `StudyView` 中逐一翻卡，點選 6 次「已記住」與 2 次「還不熟」。
  2. 評估完最後一張卡片後等待 0.25 秒轉換。
* **預期結果**：
  * 卡片消失，淡入結算面板：頂部顯示綠色大打勾圖示 `checkmark.circle` 與「本次學習完成」。
  * 複習成果卡片內顯示「正確率 75%」，佐以綠色膠囊進度條。
  * 下方清楚標明「已掌握 6 張」（綠字）與「需再加強 2 張」（紅字）。
  * 出現額外紅色選項按鈕「只重練答錯的單字 (2 張)」，以及「再複習一次」與「完成學習」雙按鈕。
* **如何還原**：點擊「完成學習」按鈕關閉頁面，或點擊「再複習一次」重啟 Session。
* **截圖檔名**：`04_study_session_finished.png`

---

### 狀態 5：設定切換狀態（學習中自動發音開關與範圍切換）
* **說明**：在翻卡學習過程中即時切換「自動發音」開關與「全部 vs 待加強」範圍 Pills。
* **標示**：`[從原始碼確認]`
* **測試資料**：目前字卡庫既有已熟練卡片（`masteryLevel >= 4`），亦有未熟練卡片（`masteryLevel < 4`）。
* **進入步驟**：
  1. 進入「English Vocabulary」的 `StudyView`。
  2. 觀察頂部標頭右側的圓形發音按鈕，點擊一下。
  3. 觀察標頭下方的範圍按鈕，點擊「待加強 (X)」Pill。
* **預期結果**：
  * 發音圖示由靜音斜線 `speaker.slash`（灰字）切換為動態波紋 `speaker.wave.2.fill`（主題綠色），觸發觸覺反饋並即時朗讀當前單字，設定值同步寫入持久化 `@AppStorage("autoPlayPronunciation")`。
  * 範圍按鈕由「全部 (8)」切換至「待加強 (X)」，選中的 Pill 背景變為深黑底白字，卡片池即時過濾並重新洗牌重置為未精通卡片集合。
* **如何還原**：再次點擊喇叭按鈕關閉自動發音；點擊「全部 (8)」Pill 恢復全量單字複習。
* **截圖檔名**：`05_study_settings_toggle.png`

---

### 狀態 6：重新開啟狀態（冷啟動後資料持久化與學習連續天數）
* **說明**：應用程式完全終止（Kill Process）後再次冷啟動，檢驗 SwiftData 資料庫、複習次數、掌握度與學習連續天數是否完整持久化。
* **標示**：`[從原始碼確認]`
* **測試資料**：完成上述「狀態 4」複習後的狀態（例如連續天數至少 1 天，累積複習 8 次）。
* **進入步驟**：
  1. 在完成學習後，退出 App 並於多工列上滑強制終止 App 行程。
  2. 重新啟動 App。
  3. 停留在「首頁」（`HomeView`）或切換至「學習統計」（`StatsView`）。
* **預期結果**：
  * App 啟動時讀取 `hasSeededKey == true`，不會重複插入重複的初始範例字卡庫。
  * 首頁頂部顯示「連續 1 天」火焰圖示與徽章（`flame.fill`）。
  * 總進度條顯示正確的「已精通 X / 總共 11 張」，掌握率與正確率如實還原。
  * 單字庫中剛剛複習過的單字掌握度圓點與最後複習時間維持最新記錄。
* **如何還原**：屬於正常持久化行為；若需重設所有資料，可解除安裝 App 或刪除 App 沙盒資料目錄。
* **截圖檔名**：`06_app_relaunch_persistence.png`

---

## 五、確認狀態分類總結

| 項目分類 | 內容說明 | 確認等級標示 |
| :--- | :--- | :--- |
| **Git 狀態與分支** | 分支為 `main`、Commit 為 `32a9213`、工作區 Clean | **`[從原始碼確認]`** / **`[已實際操作確認]`** |
| **App 架構與類別** | `ASCIIFlashCardsApp`、`ContentView`、`DeckStore`、`FlashCard`、`StudyView` 各檔案路徑與符號連結 | **`[從原始碼確認]`** |
| **資料持久化邏輯** | SwiftData Schema、`ModelContainer` 注入、UserDefaults 防重複 Seed 機制 | **`[從原始碼確認]`** |
| **語音自動朗讀** | `SpeechManager` 結合 `NaturalLanguage` 與 `AVSpeechSynthesizer` 語言偵測 | **`[從原始碼確認]`** |
| **翻卡與防呆邏輯** | `canSave` 停用按鈕、3D 翻轉角度 `flipDegree`、手勢與 Undo 堆疊邏輯 | **`[從原始碼確認]`** |
| **六大狀態實體畫面截圖** | 本次分析僅檢視專案程式碼與 Git 狀態，未啟動 iOS 模擬器或執行截圖產檔 | **`[仍待確認]`**（待後續實際啟動模擬器操作產出對應圖檔） |
| **離線發音真機音訊行為** | `AVAudioSession.setCategory(.playback)` 在實體設備靜音模式下的播放行為 | **`[仍待確認]`**（需在實體設備端驗證音效輸出） |
