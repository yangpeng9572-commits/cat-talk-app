# Cat Talk / 喵心語 — Hermes Review

本檔案由 Hermes 在 Windows Runner 驗收後更新。
OpenClaw 每輪開始前應讀取本檔案。
若 Result 為 FAIL，OpenClaw 必須優先修復，不得開新任務。

---

## Current Review Status

- Result: IDLE
- Waiting for OpenClaw fix: NO
- Last reviewed by: Hermes
- Last reviewed at: TBD

---

## Reviewed Task

- Task ID: TBD
- Task name: TBD
- Priority: TBD
- Commit reviewed: TBD
- Branch: main

---

## Validation Result

- git pull --ff-only: TBD
- Latest commit matches handoff: TBD
- Modified files match handoff: TBD
- flutter analyze: TBD
- Analyze errors: TBD
- flutter test: TBD
- Tests passed: TBD
- flutter build apk --release: TBD
- APK path: TBD
- git status --short: TBD

---

## Result Summary

TBD

---

## Failure Details

若 Result 為 FAIL，Hermes 必須填寫以下內容：

- Failed command: TBD
- Exact error message: TBD
- Suspected cause: TBD
- Allowed fix files: TBD
- Files OpenClaw may modify: TBD
- Files OpenClaw must not modify: TBD

---

## Required Next Action

| Result | OpenClaw 下一輪動作 |
|--------|-------------------|
| PASS | 可繼續 task_queue.md 下一個任務 |
| FAIL | 必須優先修復錯誤，不得開新任務 |
| BLOCKED | 需要 Andy 介入確認 |

---

## Manual Test Checklist

Hermes 手機實測後勾選：

### P0-6 刪除貓咪功能（若已驗收）

- [ ] 刪除按鈕是否顯示
- [ ] 二次確認 dialog 是否正確
- [ ] 刪除後 CatsPage 是否刷新
- [ ] 刪除後 HomePage 是否刷新
- [ ] 刪除目前選中貓是否自動切到下一隻
- [ ] 刪除最後一隻貓是否回到空狀態
- [ ] App 重開後刪除資料不復活

### P2-5 夏日窗邊活動（若已驗收）

- [ ] git pull --ff-only 成功
- [ ] flutter analyze 0 errors
- [ ] flutter test 全部通過
- [ ] flutter build apk --release 成功
- [ ] 夏日窗邊活動卡片可點擊
- [ ] 點擊後進入 SummerWindowPage
- [ ] 活動頁顯示正確
- [ ] 互動按鈕有反應
- [ ] 返回 Cat World 正常

---

## Notes

- Hermes 只驗收 Windows Runner repo 已 push 的 commit
- Hermes 不驗收 WSL2 未 commit 的修改
- Hermes 不驗收 untracked / modified 檔案
