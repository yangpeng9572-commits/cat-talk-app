# Cat Talk / 喵心語 — Handoff to Hermes

本檔案由 OpenClaw 在完成任務並 push 後更新。
Hermes 每次驗收前應先讀取本檔案。

---

## Current Handoff Status

- Status: WAITING_FOR_HERMES
- Waiting for Hermes: YES
- Last updated by: OpenClaw
- Last updated at: 2026-05-03 20:28 GMT+8

---

## P0-5 完成提示改到上方（TopToast 系統）

### 任務 ID
- Task ID: P0-5
- Task name: 完成提示改到上方（TopToast 系統建立）

### 完成的修改

- **Commit:** `f33d1da`
- **Branch:** main

### 修改內容

1. **TopToast widget**（`lib/widgets/top_toast.dart`，186 行）：
   - 位置：螢幕上方（top padding + 8）
   - 動畫：SlideTransition + FadeTransition，由上往下進入
   - 自動消失：2 秒後淡出
   - respects SafeArea
   - API：`TopToast.show()`, `.success()`, `.error()`, `.info()`
   - 顏色：暖色系（#FF8FAB 粉紅）

2. **AddCatPage SnackBar → TopToast**（3 處）：
   - 無法開啟相機 → `TopToast.error()`
   - 請先幫貓咪取名字 → `TopToast.error()`
   - 生日資料有誤 → `TopToast.error()`
   - 新增失敗 → `TopToast.error()`

3. **EditCatPage SnackBar → TopToast**（4 處）：
   - 無法開啟相機 → `TopToast.error()`
   - 名字不能為空 → `TopToast.error()`
   - 生日資料有誤 → `TopToast.error()`

4. **其他頁面 SnackBar → TopToast**（9 個檔案）：
   - cat_pose_camera_page: 3 處置換
   - cat_pose_preview_page: SnackBar → TopToast
   - cat_world_page: SnackBar → TopToast
   - daily_report_page: SnackBar → TopToast
   - history_page: SnackBar → TopToast
   - home_interaction_page: SnackBar → TopToast
   - personality_card_page: SnackBar → TopToast
   - profile_page: SnackBar → TopToast
   - summer_window_page: SnackBar → TopToast

### 修改檔案（共 11 個）

- `lib/widgets/top_toast.dart`（NEW）
- `lib/screens/add_cat_page.dart`
- `lib/screens/edit_cat_page.dart`
- `lib/screens/cat_pose_camera_page.dart`
- `lib/screens/cat_pose_preview_page.dart`
- `lib/screens/cat_world_page.dart`
- `lib/screens/daily_report_page.dart`
- `lib/screens/history_page.dart`
- `lib/screens/home_interaction_page.dart`
- `lib/screens/personality_card_page.dart`
- `lib/screens/profile_page.dart`
- `lib/screens/summer_window_page.dart`

### 驗收要求

- flutter analyze: 0 errors
- flutter test: 264 tests passed
- 驗收方式：
  1. 新增貓咪時空白名字 → 提示顯示在上方
  2. 編輯貓咪時空白名字 → 提示顯示在上方
  3. 拍照相關提示顯示在上方
  4. 提示在 2 秒後自動消失
  5. 不被 AppBar 或底部導航遮住

### Required Hermes Actions

1. `git pull --ff-only`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`（必要時）
5. 更新 `.agent/hermes_review.md` 為 PASS 或 FAIL
6. 若 PASS，更新本檔案為 IDLE 並 push

---

## Notes

- P0-5 共替換了 11 個檔案的 SnackBar 為 TopToast
- home_page 等頁面可在 P3-8 共用化階段統一處理
