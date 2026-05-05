# Cat Talk / 喵心語 — Agent Task Queue

本檔案是 OpenClaw / Hermes 的共同任務佇列。
OpenClaw 每輪任務前必須先讀取本檔案。
每輪只能選擇一個任務，不得跨任務混改。

---

## 最新完整任務清單（2026-05-03 更新）

### 建議執行順序

**第一批：必修 UX Bug（P0）**
1. P0-1：刪除貓咪後卡住，不會退回主畫面
2. P0-2：選擇貓咪第 5 隻以上無法滑動
3. P0-3：選擇貓咪點空白處可返回
4. P0-4：全 App 超出螢幕都必須能滑動
5. P0-5：完成提示改到上方

**第二批：首頁與任務內容整理（P1）**
6. P1-1：貓咪動作庫移到貓咪姿勢拍照裡
7. P1-2：移除首頁「今日還沒聽牠說話」
8. P1-3：今日陪牠小事任務內容調整

**第三批：記錄頁改版（P1）**
9. P1-4：記錄頁改成日常生活記錄 MVP
10. P1-8：貓咪照片顯示與同步修正
11. P1-9：編輯貓咪頁加入頭像編輯入口

**第四批：品牌與穩定性（P1）**
12. P1-5：App 名稱與品牌統一為「喵心語 Cat Talk」
13. P1-6：Logo 初版整合
14. P1-7：重看新手教程黑屏 / 卡住修正
15. P1-10：生日 / 領養日欄位一致化

**第五批：姿勢拍照主功能（P2）**
16. P2-1：貓咪姿勢拍照入口整理
17. P2-2：貓咪姿勢拍照必須在 App 內完成
18. P2-3：貓咪姿勢照片品質檢查 MVP
19. P2-4：姿勢分類 MVP
20. P2-5：姿勢 + 情緒 + 日常紀錄聯動

**第六批：成就與長期玩法（P2/P3）**
21. P2-6：成就頁加入解鎖條件與進度
22. P2-7：首頁人話轉喵聲 MVP
23. P3-1：她的小世界室內示意圖 Mockup
24. P3-2：她的小世界家具 / 配件 / 限定商品內容補齊
25. P3-3：夏日窗邊活動升級

**第七批：生活日記完整化（P3）**
26. P3-4：日常生活記錄第二階段：照片 + 標籤 + 時間軸
27. P3-5：日常生活記錄第三階段：日曆視圖
28. P3-6：情緒報告頁內容優化
29. P3-7：全 App 空狀態統一

**第八批：工程穩定性與工具（P3/P4）**
30. P3-8：全 App 上方提示 Top Toast 共用化
31. P3-9：導航全域防炸設計
32. P4-1：Agent Monitor Dashboard 第二階段
33. P4-2：Agent 自動排程任務狀態檔整理

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

1. **Hermes 驗收失敗修復**（hermes_review.md 為 FAIL）
2. **P0 必修 UX Bug**（使用者會卡住、看不到內容、壞掉）
3. **P1 重要功能缺口**（品牌、穩定性、核心流程）
4. **P2 UI / 體驗改善**
5. **P3 優化 / 美化 / 低風險改善**

若 Hermes Review 為 FAIL，必須優先修復，不得選新任務。

---

## 各任務詳細說明

### P0-1｜刪除貓咪後卡住，不會退回主畫面
狀態：TODO
優先順序：P0（最高）

問題：刪除貓咪後，畫面會卡住，沒有正確返回主畫面。
目標：刪除完成後自動返回首頁，並立即刷新貓咪資料。

驗收標準：
1. 在編輯貓咪頁刪除貓咪後，不會卡住
2. 二次確認後刪除成功
3. 刪除後自動關閉確認視窗
4. 自動返回主畫面
5. 主畫面立即刷新
6. 若還有其他貓，自動選到下一隻貓
7. 若沒有其他貓，顯示新增貓咪空狀態
8. 不需要使用者重新開 App

建議檢查：Navigator.pop 順序、context mounted 檢查、刪除後是否呼叫 reload/setState、bottom sheet/dialog 是否正確關閉、刪除完成後 route stack 是否異常

---

### P0-2｜選擇貓咪第 5 隻以上無法滑動
狀態：✅ DONE
優先順序：P0

已實現：Bottom sheet 貓咪列表改用 Flexible + ListView，支援 5 隻以上滑動。

問題：首頁點選「選擇貓咪」後，如果創建第 5 隻以上貓咪，選單無法往下滑。
目標：貓咪選擇清單必須支援滑動。

驗收標準：
1. 新增 5 隻以上貓咪後，選擇貓咪選單可以上下滑動
2. 第 5 隻、第 6 隻、第 7 隻都能看到
3. 可以點選任一隻貓
4. 點選後首頁資料正確切換
5. 不出現 overflow 黃黑線

建議做法：將貓咪選單清單包成 Flexible/Expanded + ListView；或設定 bottom sheet 最大高度；使用 isScrollControlled: true

---

### P0-3｜選擇貓咪點空白處可返回
狀態：TODO
優先順序：P0

問題：目前必須按手機返回鍵才能關閉選擇貓咪選單，使用者習慣點擊外部關閉。
目標：兩種方式都可以退回上一步：1. 手機返回鍵 2. 點擊選單外空白處

驗收標準：
1. 開啟選擇貓咪選單後，按返回鍵可以關閉
2. 點擊選單外空白處也可以關閉
3. 關閉後回到首頁
4. 不影響選單內按鈕操作

建議檢查：showModalBottomSheet 是否 enableDrag: true、isDismissible 是否為 true、barrierColor 是否正常

---

### P0-4｜全 App 內容超出螢幕時都必須可以滑動
狀態：✅ DONE
優先順序：P0

已實現：_showCatSwitcher() 新增 isScrollControlled: true；貓咪列表改用 Flexible(ListView)，支援 5+ 隻貓滑動；bottom sheet 底部支援拖曳關閉。

---

### P0-5｜完成提示改到上方
狀態：✅ DONE
優先順序：P0

已實現：TopToast widget 完整替換全 App 所有 SnackBar，包含 add_cat_page / edit_cat_page / home_page / history_page / daily_report_page / profile_page / cat_pose_preview_page / cat_world_page / home_interaction_page。

問題：目前完成事情後的提示視窗顯示在下方，可能被底部導覽遮住。
目標：所有成功/完成/儲存/刪除/新增提示，改成上方呈現。

驗收標準：
1. 新增貓咪成功提示顯示在上方
2. 編輯儲存成功提示顯示在上方
3. 刪除成功提示顯示在上方
4. 拍照或記錄成功提示顯示在上方
5. 不被 AppBar 擋住
6. 不遮住主要操作太久

---

### P1-1｜貓咪動作庫移到貓咪姿勢拍照裡
狀態：TODO
優先順序：P1

目標：首頁減少資訊量，將貓咪動作庫移到貓咪姿勢拍照相關流程內。

驗收標準：
1. 首頁不再直接顯示大型「貓咪動作庫」入口
2. 貓咪姿勢拍照功能內可以找到動作庫
3. 動作庫仍可正常進入

---

### P1-2｜移除首頁「今日還沒聽牠說話」
狀態：TODO
優先順序：P1

目標：移除該區塊，讓首頁更乾淨。

驗收標準：
1. 首頁不再顯示「今日還沒聽牠說話」
2. 不影響錄音/翻譯功能本身
3. 首頁版面更簡潔

---

### P1-3｜今日陪牠小事任務內容調整
狀態：TODO
優先順序：P1

目標：讓每日任務更符合新版產品方向：拍照、生活記錄、小世界互動。

需刪除：
1. 今天聽牠說一次話
2. 回應牠一次小情緒

改成：
1. 今天幫牠拍照或記錄今日生活
2. 在牠的小世界完成一次動作

---

### P1-4｜記錄頁改成日常生活記錄 MVP
狀態：TODO
優先順序：P1（第三批首位）

目標：把記錄頁改成溫馨、有意義的生活日記。

MVP 功能（第一階段）：
1. 拍照
2. 文字記錄
3. 日期顯示
4. 類似日曆或時間軸
5. 可以記錄每日小貓生活回憶

每筆記錄包含：日期、貓咪名稱、照片（可先做文字版）、文字內容、標籤

注意：建議分兩階段，第一階段先做文字生活記錄 + 日期 + 貓咪名稱 + 本地保存

---

### P1-5｜App 名稱與品牌統一為「喵心語 Cat Talk」
狀態：TODO
優先順序：P1

目標：App 名稱統一，所有殘留「貓語通」的文字都要修改。

需檢查位置：Android app label、App 內標題、首頁標題、onboarding、啟動畫面、關於頁

注意：只允許修改顯示名稱與 UI 文案，不可修改 package name、applicationId、簽名設定

---

### P1-6｜Logo 初版整合
狀態：TODO
優先順序：P1

目標：建立或整合「喵心語 Cat Talk」Logo 初版。

風格：暖色系、可愛但不幼稚、乾淨、小尺寸也看得清楚

注意：若需要正式美術素材，請先回報 Andy 確認，不可自行替換成不明來源圖片

---

### P1-7｜重看新手教程黑屏 / 卡住修正
狀態：TODO
優先順序：P1

問題：點擊「再看一次新手教程」後，可能黑屏或卡住。
目標：使用者可以安全重新觀看新手教程。

建議檢查：Navigator push/pushReplacement 使用方式、onboarding 狀態初始化、context mounted、是否有未處理 async、是否有全螢幕 overlay 沒關閉

---

### P1-8｜貓咪照片顯示與同步修正
狀態：TODO
優先順序：P1（第三批）

目標：貓咪照片在所有相關位置一致顯示。

驗收標準：
1. 首頁顯示目前貓咪照片
2. 選擇貓咪選單顯示每隻貓照片
3. 編輯貓咪頁顯示目前照片
4. 更換照片後首頁立即更新
5. 重開 App 後照片仍存在
6. 沒照片時顯示預設貓咪圖示

---

### P1-9｜編輯貓咪頁加入頭像編輯入口
狀態：TODO
優先順序：P1（第三批）

目標：讓使用者可以在編輯貓咪頁更換照片。

驗收標準：
1. 可更換貓咪照片
2. 儲存後首頁立即更新
3. 儲存後選擇貓咪視窗立即更新
4. 重開 App 後仍存在
5. 沒照片時顯示預設圖

注意：若拍照流程尚未穩定，可以先支援「從相簿選擇」

---

### P1-10｜生日 / 領養日欄位一致化
狀態：TODO
優先順序：P1（第四批）

目標：新增與編輯貓咪頁都使用一致欄位「生日 / 領養日」。

建議：保持 Cat model backward compatibility，舊欄位不要直接破壞

---

### P2-1 ～ P2-7｜姿勢拍照與體驗改善
（第五批、第六批，詳細說明略）

### P3-1 ～ P3-9｜優化與穩定性
（第七批、第八批，詳細說明略）

---

## 暫停 / 不可自動執行任務

以下任務不得自動執行，需 Andy 明確批准：
- 修改 package name / signing / build.gradle
- 修改 API key / 憑證 / .env
- 大型重構 / 自動上傳 APK / 自動發布
- git reset / stash / 強制覆蓋
- 多 Agent 同時改同一工作樹
- P2-2 貓咪姿勢拍照必須在 App 內完成（涉及 camera package）
- P1-6 Logo 初版整合（需要美術素材）

---

## 每輪回報格式

OpenClaw 每輪回報必須包含：
1. 本輪任務 ID
2. 本輪任務名稱
3. git status --short
4. 修改檔案
5. 完成內容
6. flutter analyze 結果
7. flutter test 結果
8. 是否 commit + push
9. 是否需要 Hermes 驗收
10. 是否需要 Andy 真機確認
11. 下一輪建議任務

---

## 任務狀態追蹤（2026-05-04）

| Task | Status | Notes |
|------|--------|-------|
| P0-1 | ✅ PASS | 刪除貓咪後卡住（Hermes 2026-05-03）|
| P0-2 | ✅ PASS | 第5隻以上無法滑動（Hermes 2026-05-03）|
| P0-3 | ✅ PASS | 點空白處可返回（Hermes 2026-05-03）|
| P0-4 | ✅ PASS | 全App滑動問題（Hermes 2026-05-03）|
| P0-5 | ✅ PASS | 完成提示改上方 — TopToast 替換所有 SnackBar（Hermes validated）|
| P1-1 | ✅ PASS | 動作庫已移至姿勢拍照頁（首頁按鈕已移除）|
| P1-2 | ✅ PASS | 移除今日還沒聽牠說話 — 生活文案替換錄音導向空狀態（commit c4b4a8f，Hermes pass aecd811） |
| P1-3 | ✅ PASS | 任務內容調整 — 已替換 translate/feedback → pose_photo + cat_world_interact（commit 64d3843，Hermes pass b89bd28） |
| P1-4 | ✅ DONE (commit b1ac215) | 記錄頁改生活日記 |
| P1-5 | ✅ DONE (commit c910ca6) | 品牌統一 |
| P1-6 | TODO | Logo整合（需 Andy 提供素材）|
| P1-7 | ✅ DONE (commit b4adbfc) | 新手教程黑屏 |
| P1-8 | ✅ DONE (commit e1c5654) | 照片同步修正 |
| P1-9 | ✅ DONE (已有頭像編輯入口) | 編輯頁頭像入口 |
| P1-10 | ✅ DONE (commit 3b6635b) | 生日領養日一致化 |
| P2-1 | ✅ PASS | 姿勢拍照入口整理（Hermes 2026-05-03）|
| P2-2 | TODO | 姿勢拍照必須在App內完成 |
| P2-3 | TODO | 姿勢照片品質檢查 |
| P2-4 | ✅ PASS | 姿勢分類MVP（Hermes 2026-05-03）|
| P2-5 | ✅ PASS | 姿勢+情緒+日常聯動（Hermes 2026-05-03）|
| P2-6 | ✅ DONE (commit 9008aaf) | 成就頁加入進度 |
| P2-7 | ✅ PASS_WITH_ASSET_PENDING | 人話轉喵聲MVP（Hermes 75ab4dd, 2026-05-04）|
| P3-1 | ✅ PASS | 她的小世界室內示意圖（Hermes 2026-05-03）|
| P3-2 | ✅ PASS | 小世界家具/配件內容（Hermes 2026-05-03）|
| P3-3 | ✅ DONE (commit 710bd1b) | 夏日窗邊頭像顯示（Hermes via P3-7 review window）|
| P3-7 | ✅ PASS | 全App空狀態統一（Hermes cdedea1, 2026-05-04）|
| P3-8 | ✅ PASS | TopToastService統一入口（Hermes c068f67, 2026-05-04）|
| P3-9 | ✅ DONE (phases 5-19 PASS) | 導航全域防炸設計 — 所有主要畫面已加 mounted guard（Hermes validated 2026-05-05） |
| P3-6 | ✅ DONE (commit 867369c) | 情緒報告頁貓咪頭像顯示（Hermes 2026-05-04）|
| P4-1 | ✅ PASS | Dashboard Phase2 — tools/ 更新（Hermes 0b569a2, 2026-05-05） |
| P4-2 | ✅ DONE (2026-05-05) | Agent 自動排程任務狀態檔整理 — task_queue.md / current_status.md / handoff_to_hermes.md 同步完成（2026-05-05） |

---

_Last updated: 2026-05-05 11:15 GMT+8_

## 附：P3-9 導航全域防炸設計 — 執行備忘

目標：在全 App 主要 async Navigator 呼叫點加入 `if (!mounted) return;` guard，防止 widget unmount 後 callback 執行導致崩溃。

優先檢查畫面（高風險）：
1. home_page.dart — 首頁，互動多
2. cat_world_page.dart — 已做6個guard（本次複查）
3. home_interaction_page.dart — 錄音/翻譯流程
4. cat_pose_preview_page.dart — 拍照後處理
5. daily_report_page.dart — 情緒報告

原則：
- 只加 guard，不改任何業務邏輯
- 每次只改一個檔案
- 每個 guard commit + push 後再進行下一個
- 不修改 Navigator 跳轉目標