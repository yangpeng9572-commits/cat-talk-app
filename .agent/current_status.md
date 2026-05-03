# Cat Talk / 喵心語 — Current Agent Status

本檔案記錄 OpenClaw / Hermes 的目前同步狀態。
雙方每輪開始前都應先讀取本檔案。

---

## Repo / 工作樹

### OpenClaw / WSL2
- Role: Development Agent
- Path: /home/a0938/cat_talk_proper/
- Branch: main

### Hermes / Windows Runner
- Role: Validation / Build Agent
- Path: C:\Users\a0938\cat_talk_proper\
- Branch: main

---

## 正式同步規則

唯一正式同步方式：
1. OpenClaw commit + push
2. Hermes git pull --ff-only
3. Hermes flutter analyze / flutter test / flutter build apk --release
4. Hermes 回寫驗收結果
5. OpenClaw 根據結果繼續或修錯

Hermes 不驗收 WSL2 未 commit 的修改。
OpenClaw 不直接修改 Windows repo。

---

## 目前穩定基準

- Stable branch: main
- Stable remote: origin/main
- 最新確認穩定 commit: af17dce
- 已推送 commit:
  - `af17dce`：cat management navigation and profile flow
  - `3baf846`：delete cat action in edit page
  - `0373aba`：summer window activity page

---

## 當前任務狀態

### P0-6：刪除貓咪功能 MVP
- Commit: `3baf846`
- 狀態：Hermes analyze / test / build 已通過
- 等待：手機實測

### P2-5：夏日窗邊活動點擊 MVP
- Commit: `0373aba`
- 狀態：Hermes 驗收中
- 等待：Hermes pull + analyze + test + build + 實測

---

## 是否允許 OpenClaw 開新任務

- 若 Hermes Review 為 FAIL：OpenClaw 必須優先修錯
- 若 git status 有非預期 modified：必須停止
- 若雙工作樹未同步：先同步再執行

---

## 無關檔案提醒

Windows repo 目前可能有以下 untracked，不得加入 commit：
- C∅™Users∅™a0938∅™.hermes∅™windows_runner/
- cat-talk-2026-05-02.apk

---

## 下一步建議

1. Hermes pull 後驗收 P2-5
2. P0-6 / P2-5 手機實測通過後，更新本檔穩定基準
3. OpenClaw 依 task_queue 繼續下一個任務
