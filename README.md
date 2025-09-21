This README documentation, including both Chinese and English versions, was written and translated with AI assistance.

# Link Game (SwiftUI)

一款以 SwiftUI 製作的「連連看」小遊戲。特色包含：
- 經典模式（簡單 / 困難）、練習模式（自選起始關卡）、無盡模式
- 最多 2 次轉彎的 BFS 尋路（支援走到外框）
- 多種掉落規則（向下 / 向上 / 向左 / 向右 / 左右分裂 / 上下分裂 / 向中心）
- 第 9 關「終極配對」規則（pairNNN_1 必須配對 pairNNN_2）
- 無可行步自動洗牌（困難模式會扣提示再洗）
- SwiftUI Canvas 動態繪製連線路徑
- 音效快取播放（AVAudioPlayer + NSDataAsset / Bundle 資源）

本專案適合作為 SwiftUI 遊戲邏輯與 BFS 路徑搜尋的學習範例，也可以直接遊玩。

## 遊戲畫面

- 上方顯示：關卡、模式名稱 / 掉落風格、提示數、暫停、進度條
- 中間為 7 x 16 盤面
- 右上工具列：分數、重新開始、返回
- 成功配對會顯示藍白雙線路徑，並有音效與加秒

## 遊戲模式

- 經典簡單（Classic Easy）
  - 每關提示數固定為 3
  - 關卡 1 會以「相鄰配對較多」的方式佈局，降低難度
  - 最多到第 10 關

- 經典困難 (Classic Hard)
  - 進入下一關時提示數會「累加 +2」（不重置為 3）
  - 無可行步時若提示數 > 0，會扣 1 後強制洗牌；否則直接失敗
  - 最多到第 10 關

- 練習模式 (Practice)
  - 可指定起始關卡
  - 完成後會停留在該關（按鈕文案為「完成！重新開始本關」）

- 無盡模式 (Endless)
  - 禁止暫停
  - 每關隨機一種掉落風格（名稱會顯示在標題處）
  - 會記錄最佳層數與最佳分數（使用 UserDefaults）
  - 失敗時會更新最佳成績

## 關卡規則

- 時間：每關基準時間會隨關卡遞減（120 秒起，每關 -5 秒，最低 30 秒）
- 配對加秒：每成功配對 +3 秒（不超過該關基準時間）
- 過關：清完所有配對（分數加成：加上剩餘秒數）
- 第 9 關「終極配對」：
  - 圖片名稱為 pairNNN_1 / pairNNN_2
  - 只能「同 pair，且尾碼不同」才算可配對
  - 不會觸發掉落重整（其他關卡都會依風格掉落）

## 操作方式

- 點擊兩格相同（或終極配對規則）即可消除
- 允許最多 2 次轉彎，且可走到盤面外框再折返
- 提示：消耗提示數，會高亮一組目前能連線的配對
- 暫停：無盡模式禁用，其餘模式可暫停（暫停時圖片以眼睛劃線圖示遮蔽）

## 技術重點

- SwiftUI + ObservableObject
  - 使用 @Published 狀態驅動 UI（盤面 grid、路徑 currentPath、提示高亮等）
  - Canvas 繪製連線路徑（雙層線條：藍外白內）

- BFS 尋路（核心在 LinkGameModel.findPath）
  - 盤面含外框（rows+2 x cols+2），允許路徑走到外框
  - 最多 2 次轉彎（Z、L、U 型）
  - parent[r][c][dir] 回溯路徑，構成完整座標序列

- 掉落機制（applyLevelFall）
  - 依關卡或無盡模式風格，對盤面進行重整
  - 提供 7 種風格：down/up/left/right/splitLR/splitUD/center
  - 第 9 關不掉落

- 洗牌策略（shuffleIfNeeded / handleNoMovesShuffle）
  - 重新打散剩餘方塊，保證（或嘗試）產生至少一組可行配對
  - 困難模式在無可行步時，若提示數 > 0 先扣 1 再強制洗牌，否則遊戲結束

- 音效播放（SoundPlayer）
  - 快取 AVAudioPlayer，支援多種副檔名（wav/mp3/aiff/m4a/caf）與 NSDataAsset

## 專案結構（重點檔案）

- ContentView.swift
  - ContentView：UI 主畫面、盤面呈現、Canvas 路徑、過關/失敗覆蓋層
  - TileView：單一格子的外觀（圖片、選取/提示邊框、暫停遮蔽）
  - LinkGameModel：核心遊戲邏輯（盤面、計時、配對、BFS、掉落、洗牌、提示、無盡紀錄）
  - SoundPlayer：簡易音效管理

## 資源需求

- 遊戲圖片資源
  - 一般關卡：檔名格式「檔案_001」~「檔案_035」等（可自行替換或調整數量）
  - 第 9 關：pair 圖片名需為「pairNNN_1 / pairNNN_2」（NNN 為 3 位數）
- 背景圖：back002
- 音效（可放在 Bundle 或 Data Asset）
  - clickSound、combo（可自行替換名稱與副檔名）

若缺少資源，請在 Assets 中新增對應名稱的圖片與音效，或修改程式中的名稱常數。

## 建置與執行

1. 使用 Xcode 開啟專案（建議 Xcode 15+）
2. 將圖片與音效資源加入 Assets 或專案 Bundle
3. 選擇 iOS 模擬器或實機後，直接 Build & Run

## 自訂與擴充

- 盤面大小：在 LinkGameModel 中的 rows / cols 可調整（注意偶數格總數）
- 掉落風格：可在 applyLevelFall 中擴增新風格
- 關卡規則：可調整 baseTimeForLevel、bonusPerMatch、提示規則等
- 路徑樣式：修改 Canvas 的線條顏色、寬度或動畫
- 模式與 UI：可新增新模式或不同計分方式

## 已知限制

- BFS 以步進方式搜尋，盤面過大時可能影響效能（目前 7x16 表現良好）
- 資源名稱依賴固定格式，替換時請一併調整對應常數或生成邏輯

## 截圖

（可自行加入 App 截圖）

## 授權

本專案採用 MIT License。你可以自由使用、修改與散布，但請保留授權條款。

我幫你看過這份 README，整體內容完整、條理清楚，沒有錯誤或需要修正的地方 👍。結構上已經很適合作為專案說明，涵蓋了特色、玩法、技術細節、建置方法與限制。

唯一的小建議（非必須）：

* 如果要公開在 GitHub，可以在最上方加上簡短的一行 **專案簡介（英文 tagline）**，讓人第一眼就知道這是一款 SwiftUI 製作的連連看遊戲，例如：

  > *A tile-matching "Link Game" built with SwiftUI, featuring multiple modes, BFS pathfinding, and dynamic drop mechanics.*

---

以下是完整英文翻譯版本：

---

# Link Game (SwiftUI)

A tile-matching puzzle game built with SwiftUI. Features include:

* Classic modes (Easy / Hard), Practice mode (custom start level), Endless mode
* BFS pathfinding with up to 2 turns (supports going through the border)
* Multiple drop rules (down / up / left / right / splitLR / splitUD / center)
* Level 9 "Ultimate Pair" rule (pairNNN\_1 must match pairNNN\_2)
* Automatic shuffle when no moves are available (Hard mode deducts a hint before shuffling)
* Dynamic path rendering using SwiftUI Canvas
* Cached sound playback (AVAudioPlayer + NSDataAsset / Bundle resources)

This project serves as a learning example for SwiftUI game logic and BFS pathfinding, and it can also be played directly as a game.

## Gameplay UI

* Top bar: level, mode name / drop style, hint count, pause, progress bar
* Middle: 7 x 16 board
* Top-right toolbar: score, restart, back
* Successful matches display a dual-colored path (blue outer, white inner), with sound and time bonus

## Game Modes

* **Classic Easy**

  * Each level starts with 3 hints
  * Level 1 is arranged with many adjacent pairs for lower difficulty
  * Up to level 10

* **Classic Hard**

  * Hints accumulate (+2 per level), not reset to 3
  * If no moves: if hints > 0, deduct 1 and force shuffle; otherwise fail
  * Up to level 10

* **Practice**

  * Choose starting level
  * After completion, stays on the same level (button shows “Completed! Restart this level”)

* **Endless**

  * Pause disabled
  * Each level randomly uses one drop style (name shown in title)
  * Best depth and score are recorded (via UserDefaults)
  * On failure, best records are updated

## Level Rules

* Time: starts at 120s, decreases by 5s per level, minimum 30s
* Match bonus: +3s per successful match (capped at base time of the level)
* Clear condition: match all tiles (score bonus = remaining time)
* Level 9 "Ultimate Pair":

  * Tile names are pairNNN\_1 / pairNNN\_2
  * Only same pair with different suffix can match
  * No drop reorganization (other levels do drop)

## Controls

* Tap two identical tiles (or following ultimate pair rule) to eliminate
* Up to 2 turns allowed, paths can go through the border
* Hint: consumes 1 hint, highlights one valid pair
* Pause: disabled in Endless mode, available in others (tiles covered with eye-slash icon)

## Technical Highlights

* **SwiftUI + ObservableObject**

  * UI driven by @Published states (grid, currentPath, hint highlights, etc.)
  * Canvas used for path rendering (dual line: blue outer, white inner)

* **BFS Pathfinding (LinkGameModel.findPath)**

  * Board includes border (rows+2 x cols+2) for outside paths
  * Up to 2 turns allowed (Z, L, U shapes)
  * parent\[r]\[c]\[dir] backtracking builds full coordinate sequence

* **Drop Mechanism (applyLevelFall)**

  * Board reorganized according to level or Endless style
  * 7 styles: down / up / left / right / splitLR / splitUD / center
  * Level 9 disables drop

* **Shuffle Strategy (shuffleIfNeeded / handleNoMovesShuffle)**

  * Re-shuffle remaining tiles to ensure (or attempt) at least one valid match
  * Hard mode: if no moves, deduct 1 hint then shuffle; if no hints, game over

* **Sound Playback (SoundPlayer)**

  * Cached AVAudioPlayer, supports multiple formats (wav/mp3/aiff/m4a/caf) and NSDataAsset

## Project Structure (Key Files)

* **ContentView\.swift**

  * ContentView: main UI, board rendering, Canvas path, overlays (clear/fail)
  * TileView: single tile appearance (image, selection/hint border, pause cover)
  * LinkGameModel: core logic (board, timer, matching, BFS, drop, shuffle, hints, Endless record)
  * SoundPlayer: simple sound management

## Assets Required

* Tile images

  * Normal levels: filenames like “file\_001” \~ “file\_035” (can be replaced or adjusted)
  * Level 9: pair images must be named “pairNNN\_1 / pairNNN\_2” (NNN is 3 digits)
* Background image: back002
* Sound effects (placed in Bundle or Data Asset)

  * clickSound, combo (can be replaced with different names/formats)

If assets are missing, add them in Assets or adjust constants in code.

## Build & Run

1. Open project with Xcode (recommended Xcode 15+)
2. Add image and sound assets to Assets or Bundle
3. Select iOS simulator or device, then Build & Run

## Customization & Extension

* Board size: adjustable via rows / cols in LinkGameModel (ensure even number of tiles)
* Drop styles: extend applyLevelFall with new styles
* Level rules: modify baseTimeForLevel, bonusPerMatch, hint rules, etc.
* Path style: change Canvas line colors, width, or animations
* Modes & UI: add new modes or scoring methods

## Known Limitations

* BFS uses stepwise search; very large boards may affect performance (7x16 runs well)
* Asset naming depends on fixed format; replacements require updating constants or generation logic

## Screenshots

(Add app screenshots here)

## License

This project is licensed under the MIT License. You are free to use, modify, and distribute, but please retain the license notice.

---
