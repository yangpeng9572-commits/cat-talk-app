# Cat Talk / 喵心語 — Agent Task Queue

本檔案是 OpenClaw / Hermes 的共同任務佇列。
OpenClaw 每輪任務前必須先讀取本檔案。
每輪只能選擇一個任務，不得跨任務混改。

---

## 目前穩定基準

- Stable branch: main
- Stable source: origin/main
- 最新已同步基準：以 Hermes 驗收通過並 push 的最新 commit 為準
- OpenClaw 開發路徑：`/home/a0938/cat_talk_proper/`
- Hermes 驗收路徑：`C:\Users\a0938\cat_talk_proper\`

---

## 任務選擇規則

OpenClaw 每輪選任務時，依照以下順序：

1. Hermes 驗收失敗修復
2. P0 會讓使用者卡住 / 壞掉 / 資料錯誤
3. P1 重要功能缺口
4. P2 UI / 體驗改善
5. P3 優化 / 美化 / 低風險改善

若 Hermes Review 為 FAIL，必須優先修復，不得選新任務。

---

## P0｜最高優先

### P0-6：刪除貓咪功能 MVP
狀態：✅ WSL2 已 commit + push，Hermes 實測中

需求：
- 編輯貓咪頁有「刪除這隻貓咪」
- 有二次確認 dialog
- 可刪除指定貓咪
- 刪除後 CatsPage 立即刷新
- 刪除後 HomePage 立即刷新
- 刪除目前選中貓時，自動切到下一隻
- 沒有任何貓時，回到新增貓咪空狀態

目前 commit：3baf846 feat: add delete cat action in edit page

---

### P0-1：新手教程 replayOnboarding 黑屏回歸測試
狀態：✅ af17dce 已整合，需 Hermes 回歸確認

需求：
- 點「再看一次新手教程」不黑屏、不 freeze、可正常重新播放

---

### P0-2：翻譯記錄頁空白 / 真實紀錄確認
狀態：✅ af17dce 已整合，需 Hermes 回歸確認

需求：
- 有真實翻譯紀錄時 HistoryPage 正確顯示
- 不再依賴 mock data
- 關閉 App 重開後紀錄仍存在

---

## P1｜重要功能

### P1-1：新增 / 編輯貓咪資料完整性確認
狀態：✅ af17dce 已整合，需 Hermes 回歸確認

需求：
- 新增貓咪後首頁立即刷新
- 編輯後立即刷新
- App 重開後資料仍存在

---

### P1-2：貓咪頭像持久化確認
狀態：✅ af17dce 已整合，需 Hermes 回歸確認

需求：
- 編輯頁選擇頭像後首頁 / CatsPage 顯示
- App 重開後頭像仍存在

---

## P2｜體驗改善

### P2-5：夏日窗邊活動點擊 MVP
狀態：✅ WSL2 已 commit + push，Hermes 驗收中

需求：
- Cat World 活動卡片可點擊
- 點擊後進入 SummerWindowPage
- 活動頁顯示窗邊場景、說明、互動按鈕、進度、商品展示

目前 commit：0373aba feat: add summer window activity page

---

### P2-4：小房間滑到底 / overflow 問題
狀態：待處理

需求：
- Cat World 小房間頁面不 overflow
- 小螢幕可完整滑動
- 不出現黃黑警告線

---

## P3｜低風險優化

### P3-1：整理 withOpacity deprecated 警告
狀態：待處理

需求：
- 分批處理 deprecated withOpacity
- 每批只改少量檔案
- 不影響 UI 視覺
- analyze 仍為 0 errors

---

## 暫停 / 不可自動執行任務

以下任務不得自動執行，需 Andy 明確批准：
- 修改 package name / signing / build.gradle
- 修改 API key / 憑證 / .env
- 大型重構 / 自動上傳 APK / 自動發布
- git reset / stash / 強制覆蓋
- 多 Agent 同時改同一工作樹

---

## 每輪回報格式

OpenClaw 每輪回報必須包含：
1. 本輪任務 ID
2. 任務目標
3. 修改檔案
4. 是否符合允許範圍
5. git status --short
6. git diff --name-only
7. git diff --stat
8. analyze / test 結果
9. 是否 commit + push
10. 給 Hermes 的下一步
11. 是否需要 Andy 介入

---

## P3-1 進度追蹤

### 已完成

| Batch | 檔案 | Commit | Hermes 狀態 |
|-------|------|--------|-------------|
| Batch 1 | lib/screens/daily_task_card.dart | `685e186` | ✅ PASS |
| Batch 2 | lib/widgets/*.dart（7 檔） | `99b8f7b` | ✅ PASS |
| Batch 3 | lib/screens/ 其餘 10 檔（~28 處） | `45d6b5d` | ⏳ 待 Hermes 驗收 |

### 待處理

- Batch 4: daily_report_page.dart、personality_card_page.dart、pose_recognition_page.dart、love_meter_page.dart、home_page.dart、memory_cards_page.dart、home_interaction_page.dart（~58 處）

