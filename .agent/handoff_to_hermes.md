# Cat Talk / 喵心語 — Handoff to Hermes

本檔案由 OpenClaw 在完成任務並 push 後更新。
Hermes 每次驗收前應先讀取本檔案。

---

## Current Handoff Status

- Status: WAITING_FOR_HERMES
- Waiting for Hermes: YES
- Last updated by: OpenClaw
- Last updated at: 2026-05-03 19:53 GMT+8

---

## P0-5 完成提示改到上方

### 任務 ID
- Task ID: P0-5
- Task name: 完成提示改到上方（TopToast 系統建立）

### 完成的修改

- **Commit:** `3212c41`
- **Branch:** main

### 修改內容

1. **新增 TopToast widget**（`lib/widgets/top_toast.dart`，186 行）：
   - 位置：螢幕上方（top padding + 8）
   - 動畫：SlideTransition + FadeTransition，由上往下進入
   - 自動消失：2 秒後淡出
   - respects SafeArea
   - API：`TopToast.show()`, `.success()`, `.error()`, `.info()`

2. **替換 AddCatPage SnackBar**（3 處）：
   - 無法開啟相機 → `TopToast.error()`
   - 請先幫貓咪取名字 → `TopToast.error()`
   - 生日資料有誤 → `TopToast.error()`
   - 新增失敗 → `TopToast.error()`

3. **替換 EditCatPage SnackBar**（4 處）：
   - 無法開啟相機 → `TopToast.error()`
   - 名字不能為空 → `TopToast.error()`
   - 生日資料有誤 → `TopToast.error()`

### 修改檔案

- `lib/widgets/top_toast.dart`（NEW，186 行）
- `lib/screens/add_cat_page.dart`（import + 3 處替換）
- `lib/screens/edit_cat_page.dart`（import + 4 處替換）

### 驗收要求

- flutter analyze: 0 errors
- flutter test: 264 tests passed
- 驗收方式：
  1. 新增貓咪時空白名字 → 提示顯示在上方
  2. 編輯貓咪時空白名字 → 提示顯示在上方
  3. 提示在 2 秒後自動消失
  4. 不被 AppBar 或底部導航遮住
  5. 顏色為暖色系（#FF8FAB）

### Required Hermes Actions

1. `git pull --ff-only`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`（必要時）
5. 更新 `.agent/hermes_review.md` 為 PASS 或 FAIL
6. 若 PASS，更新本檔案為 IDLE 並 push

---

## 上一輪任務

- P0-4：全 App 超出螢幕都必須能滑動（Hermes PASS）

---

## Notes

- P0-5 共替換了 2 個檔案的 7 處 SnackBar
- 其他頁面（home_page, profile_page 等）可在下一輪替換
- 這是 MVP 版本，後續可用 P3-8 共用化