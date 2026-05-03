# Cat Talk / 喵心語 — Handoff to Hermes

本檔案由 OpenClaw 在完成任務並 push 後更新。
Hermes 每次驗收前應先讀取本檔案。

---

## Current Handoff Status

- Status: WAITING_FOR_HERMES
- Waiting for Hermes: YES
- Last updated by: OpenClaw
- Last updated at: 2026-05-03 20:49 GMT+8

---

## P0-5：完成提示改到上方（home_page + emotion_card）

### 任務 ID
- Task ID: P0-5（全 App 完成提示改到上方）
- Task name: 完成提示改到上方

### 完成的修改

- **Commit:** `f7431bd`
- **Branch:** main

### 修改內容

**home_page.dart:**
- `_showSnackBar('需要麥克風權限才能錄音喔！', isError: true)` → `TopToast.error()`
- `_showSnackBar('錄音太短，再試一次 🐱', isError: true)` → `TopToast.error()`
- `_showSnackBar('翻譯失敗了，再試一次吧 🐱', isError: true)` → `TopToast.error()`
- `_showBriefToast()` SnackBar → `TopToast.show()`（愛心圖示，上方顯示）
- `_addBondScore()` feedback SnackBar → `TopToast.success()`

**emotion_card.dart:**
- `_onActionTapped()` SnackBar → `TopToast.show()`（愛心圖示）
- `_onFeedbackCorrect()` SnackBar → `TopToast.success()`

**刪減：100 行 SnackBar 樣板碼，新增：18 行 TopToast 呼叫**

### 修改檔案

- `lib/screens/home_page.dart`
- `lib/widgets/emotion_card.dart`

### 驗收要求

- flutter analyze: 0 errors
- flutter test: 264 tests passed
- 驗收方式：
  1. 錄音權限失敗 → TopToast 顯示在上方
  2. 錄音太短 → TopToast 顯示在上方
  3. 翻譯失敗 → TopToast 顯示在上方
  4. 默契值增加 → TopToast.success 顯示在上方
  5. 點擊動作完成 → TopToast 愛心顯示在上方
  6. 翻譯回饋正確 → TopToast.success 顯示在上方
  7. 確認提示不被底部導覽列遮住

### Required Hermes Actions

1. `git pull --ff-only`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`（必要時）
5. 更新 `.agent/hermes_review.md` 為 PASS 或 FAIL
6. 若 PASS，更新本檔案為 IDLE 並 push

---

## P0-2：選擇貓咪第 5 隻以上無法滑動（已驗收 PASS，commit d6619a3）

### 任務 ID
- Task ID: P0-2
- Task name: 選擇貓咪第 5 隻以上無法滑動

### 完成的修改

- **Commit:** `d6619a3`
- **Branch:** main

### 修改內容

- `_showCatSwitcher()` bottom sheet 內的 `Flexible(child: ListView(shrinkWrap: true))` 改為 `Container(constraints: const BoxConstraints(maxHeight: 400), child: ListView(shrinkWrap: true))`
- 固定最大高度 400px，內容超出時可自然滾動
- 5 隻以上貓咪時選擇清單可正常滑動

### 修改檔案

- `lib/screens/home_page.dart`（1 行變更）

---

## Notes

- P0-5 共替換 home_page.dart（5處）+ emotion_card.dart（2處）殘留 SnackBar
- TopToast 使用 overlay 顯示在螢幕上方，不被 bottom navigation 遮住
- P0-2 已驗收 PASS（Hermes 2026-05-03 19:47）
- 下一個建議任務：P1-1（貓咪動作庫移到姿勢拍照內）