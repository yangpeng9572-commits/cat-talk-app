# Cat Talk / 喵心語 — Handoff to Hermes

本檔案由 OpenClaw 在完成任務並 push 後更新。
Hermes 每次驗收前應先讀取本檔案。

---

## Current Handoff Status

- Status: WAITING_FOR_WINDOWS_RUNNER
- Waiting for Hermes: YES
- Last updated by: OpenClaw 小龍女
- Last updated at: 2026-05-04 07:12 PM (Asia/Taipei)

---

## Task: P2-2A CameraPreview Compliance Validation

- **Task ID:** P2-2A
- **Task name:** App 內 CameraPreview 姿勢拍照 MVP
- **Owner:** Hermes Windows Runner
- **Need:** Windows Runner 實機驗收

### 修正背景

上一版使用 `image_picker` 跳出系統相機 App，不符合「App 內 CameraPreview」規格。
本版已重寫為 `camera package + CameraPreview`，完整在 App 內完成拍照。

### 合規檢查清單

| 項目 | 狀態 |
|------|------|
| 使用 camera package | ✅ 是 |
| CameraController | ✅ 有（`_controller`） |
| availableCameras() | ✅ 有（`_initCamera()` 內呼叫） |
| controller.initialize() | ✅ 有 |
| CameraPreview | ✅ 有（`CameraPreview(_controller!)` 疊加在引導框下方）|
| CatPoseCameraFrame 疊在 CameraPreview 上 | ✅ 是（Stack 內引導框在上層）|
| controller.takePicture() | ✅ 有（`_takePhoto()` 內使用）|
| 拍照過程不跳出系統相機 App | ✅ 是，全程在 App 內 |
| CameraController dispose | ✅ 有（`dispose()` 內呼叫）|
| mounted 檢查 | ✅ 有（所有 async setState/Navigator 前都有）|
| availableCameras 為空不 crash | ✅ 有，`_cameras.isEmpty` 判斷 + 錯誤訊息 |
| Camera 初始化失敗不黑屏 | ✅ 有，`_hasError` 狀態顯示錯誤訊息 + 重試按鈕 |
| 權限拒絕不黑屏 | ✅ 有，`Permission.camera.request()` 失敗顯示 Toast |
| 拍照按鈕防連點 | ✅ 有，`_isTakingPhoto` 狀態鎖定 |
| 拍照成功進入預覽頁 | ✅ 有 |
| 無 AI | ✅ 確認 |
| 無照片品質檢查 | ✅ 確認 |
| 無雲端串接 | ✅ 確認 |

### image_picker 狀態

- ❌ 已移除（不再使用 image_picker）
- `lib/screens/cat_pose_camera_page.dart` 不再 import image_picker

### 修改檔案（共 3 個）

| 檔案 | 變更 |
|------|------|
| `lib/screens/cat_pose_camera_page.dart` | 完全重寫（~320行）新增 CameraController / CameraPreview / takePicture |
| `lib/screens/cat_pose_preview_page.dart` | 無變更（已在正確狀態）|
| `lib/screens/home_page.dart` | 無變更（已在正確狀態）|

### ⚠️ cat_world_page.dart 風險警示

| 檔案 | 狀態 |
|------|------|
| `lib/screens/cat_world_page.dart` | ⚠️ 非本任務修改，預先存在，已標記為風險檔案 |

- diff 內容：只新增 `if (!mounted) return;` 的安全檢查
- **與 P2-2A 無直接關聯**，懷疑是早期自主心跳產生的修改
- **不可 commit、不可 reset、不可格式化、不可修改**
- 待後續单独確認歸屬

### git status --short

```
M lib/screens/cat_pose_camera_page.dart
M lib/screens/cat_pose_preview_page.dart
M lib/screens/cat_world_page.dart   ← ⚠️ 非本任務風險檔案
M lib/screens/home_page.dart
```

### Required Hermes Actions

1. `git pull --ff-only`（如需要）
2. `flutter analyze` — 確認 0 errors
3. `flutter test` — 確認 264 tests passed
4. **實機驗收**：
   - 相機權限拒絕 → 顯示 Toast，不黑屏
   - 無相機或初始化失敗 → 顯示錯誤訊息 + 重試，不黑屏
   - CameraPreview 正常顯示在畫面中
   - CatPoseCameraFrame 引導框正確疊在 CameraPreview 上
   - 拍照按鈕防連點
   - 拍照成功進入 cat_pose_preview_page.dart
   - 重新拍攝回到 App 內相機頁（非跳轉系統相機）
   - 使用這張照片顯示「姿勢觀察」Toast，無假分析

---

## Notes

- OpenClaw 待機，等待 Hermes Windows Runner 實機驗收結果
- 若 FAIL，回報錯誤，OpenClaw 下一輪優先修錯
- cat_world_page.dart 的 modified 是之前任務殘留，與本任務無關，不可處理