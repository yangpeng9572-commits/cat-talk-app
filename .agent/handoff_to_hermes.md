# Cat Talk / 喵心語 — Handoff to Hermes

本檔案由 OpenClaw 在完成任務並 push 後更新。
Hermes 每次驗收前應先讀取本檔案。

---

## Current Handoff Status

- Status: WAITING_FOR_HERMES
- Waiting for Hermes: YES
- Last updated by: OpenClaw
- Last updated at: 2026-05-03 21:56 UTC

---

## P1-3：今日陪牠小事任務內容調整

### 任務 ID
- Task ID: P1-3
- Task name: 今日陪牠小事任務內容調整

### 完成的修改

- **Commit:** `64d3843`
- **Branch:** main

### 修改內容

**lib/models/daily_task.dart:**
- TaskType enum 新增 `pose_photo`（拍照記錄）和 `cat_world_interact`（小世界互動）
- `translate_meow` 和 `give_feedback` 標記為「已停用，等待產品調整」
- emoji/label extension 完整覆盖所有 7 種 TaskType（含 translate_meow）

**lib/services/task_companion_service.dart:**
- `getTitle()`: `pose_photo` → "今天幫她拍照或記錄"；`cat_world_interact` → "在小世界完成一次動作"
- `getDescription()`: `pose_photo` → "拍張照片或寫下今天的小日記"；`cat_world_interact` → "在小世界裡和她互動一下"
- `getCompletionMessage()`: `pose_photo` → "這一刻被好好記錄下來了 🐾"；`cat_world_interact` → "她的小世界又溫暖了一點 🏡"

**lib/services/daily_task_service.dart:**
- `_generateTodayTasks()`: 原本三個任務（translate, report, feedback）改為（report, pose_photo, cat_world_interact）
- 舊的 translate_meow 和 give_feedback 任務類型保留但不再出現在每日任務中

**lib/screens/cat_pose_preview_page.dart:**
- `_usePhoto()` 成功後呼叫 `taskService.updateTaskProgress(TaskType.pose_photo)`
- 新增 `_initTaskService()` 在 initState 中初始化 DailyTaskService

**lib/screens/cat_world_page.dart:**
- `_onUnlock()` 成功後呼叫 `_taskService.updateTaskProgress(TaskType.cat_world_interact)`
- `_onEquip()` 成功後呼叫 `_taskService.updateTaskProgress(TaskType.cat_world_interact)`
- 新增 `_initTaskService()` 和 `_taskService` field

### 修改檔案

- `lib/models/daily_task.dart`
- `lib/services/task_companion_service.dart`
- `lib/services/daily_task_service.dart`
- `lib/screens/cat_pose_preview_page.dart`
- `lib/screens/cat_world_page.dart`

### 驗收要求

- `flutter analyze`: 0 errors（focus on the 5 modified files）
- `flutter test`: 264 tests passed（注意：some tests may fail due to pre-existing withValues API issue, not introduced by this commit）
- 驗收方式：
  1. `flutter analyze` on the 5 modified files — no new errors in these files
  2. Check that the 3 daily tasks are: "看看她今天的小心情" / "今天幫她拍照或記錄" / "在小世界完成一次動作"
  3. Verify that pose_photo task completes after saving a pose photo
  4. Verify that cat_world_interact task completes after unlocking/equipping an item

### Pre-existing Issues (NOT introduced by this commit)

- `withValues` method errors: Flutter 3.24.0 doesn't support `Color.withValues()` API (introduced in Flutter 3.27+). These errors exist across the entire codebase and are not caused by this commit.
- All 5 files modified in this commit should have 0 new errors.

### Required Hermes Actions

1. `git pull --ff-only`
2. `flutter analyze lib/models/daily_task.dart lib/services/task_companion_service.dart lib/services/daily_task_service.dart lib/screens/cat_pose_preview_page.dart lib/screens/cat_world_page.dart`（確認這5個檔案無新 error）
3. `flutter test`（確認全部通過）
4. `flutter build apk --release`（必要時）
5. 更新 `.agent/hermes_review.md` 為 PASS 或 FAIL
6. 若 PASS，更新本檔案為 IDLE 並 push

---

## 上輪完成：P0-5（完成提示改到上方）

- **Commit:** `68a18bd`
- **內容：** 全 App 最後一個 SnackBar 改為 TopToast.info

---

## Notes

- P1-3 任務調整：原本的「今天聽她說一次話」和「回應她一次小情緒」已停用
- 新的三個每日任務：報告、拍照、小世界互動
- 下一個建議任務：P1-4（記錄頁改成日常生活記錄 MVP）