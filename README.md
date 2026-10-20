# MyCards

以極簡與自然溫潤紙質風格設計的 iOS 單字卡學習 App。

---

## 設計特色

-  **和紙暖米白底色** (`#F7F5F0`)：溫潤自然，減少高對比視覺疲勞
-  **紙質手感單字卡**：柔和微陰影、細緻圓角、流暢 3D 紙卡翻轉
-  **聚焦學習本質**：去除干擾元素，採用清晰自然大小寫無襯線體
-  **自然草木礦物色彩**：若草綠、柴染黃、鐵紺藍、薄墨灰與經典絳紅
-  **原生數據儀表板**：平滑圓角膠囊進度條、掌握度橫向柱狀圖與成就解鎖系統
-  **本地資料持久化**：支援自訂字卡庫、新增編輯與學習進度追蹤

---

##  主要功能

-  **翻卡學習 (Study)** — 3D 翻轉動畫，輕點查看釋義，支援「還不熟 / 已記住」快速記憶評分
-  **字卡庫管理 (Decks)** — 依主題或檢定建立、編輯與管理多組字卡庫
-  **學習統計 (Analytics)** — 視覺化掌握度分佈 (Lv.0 ~ Lv.5)、複習正確率與成就徽章
-  **筆記本式表單 (Forms)** — 簡潔無框輸入體驗，支援詞性、例句、難度與自訂標籤

---

## 技術架構

```
ASCIIFlashCards/
├── Models/
│   └── FlashCard.swift          # FlashCard, Deck, PartOfSpeech, Difficulty
├── ViewModels/
│   └── DeckStore.swift          # ObservableObject + UserDefaults 持久化
├── Views/
│   ├── ASCIIHelpers.swift       # 設計系統 (Color, Font, mujiCard 修飾符)
│   ├── ContentView.swift        # TabView 根視圖 (首頁 / 單字庫 / 學習統計)
│   ├── HomeView.swift           # 今日學習儀表板 + 快速複習入口
│   ├── DeckListView.swift       # 文具收納盒風格字卡庫清單
│   ├── DeckDetailView.swift     # 單字卡詳情展開與管理
│   ├── StudyView.swift          # 紙質單字卡 3D 翻轉學習核心
│   ├── AddCardView.swift        # 筆記本式表單 (新增/編輯單字庫與單字)
│   └── StatsView.swift          # 學習數據分析與掌握度圖表
└── Resources/
    └── Assets.xcassets
```

---

## 需求環境

- Xcode 15+
- iOS 17.0+
- Swift 5.9+

---

## 執行專案

```bash
open ASCIIFlashCards/ASCIIFlashCards.xcodeproj
```
