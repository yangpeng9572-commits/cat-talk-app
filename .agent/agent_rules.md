# Cat Talk / 喵心語 — 雙 Agent 協作規則

本專案採用雙工作樹協作：

- OpenClaw / WSL2 開發路徑：
  /home/a0938/cat_talk_proper/

- Hermes / Windows Runner 驗收路徑：
  C:\Users\a0938\cat_talk_proper\

兩邊不得直接共用同一工作樹。
OpenClaw 不得改用 /mnt/c/Users/a0938/cat_talk_proper 開發。
Hermes 不驗收 WSL2 未 commit 的修改。

---

## 一、唯一正式同步流程

OpenClaw 開發完成後：

1. OpenClaw 在 WSL2 完成任務
2. OpenClaw commit + push
3. Hermes 在 Windows repo 執行 git pull --ff-only
4. Hermes 執行：
   - flutter analyze
   - flutter test
   - 必要時 flutter build apk --release
5. Hermes 回報驗收結果
6. 若 PASS，OpenClaw 可進下一任務
7. 若 FAIL，OpenClaw 下一輪必須先修錯，不可開新任務

---

## 二、OpenClaw 職責

OpenClaw 是開發 Agent，負責：

1. 每輪只處理一個任務
2. 每輪開始前必須執行：git status --short
3. 若有非預期 modified / untracked，必須停止並回報
4. 僅修改任務允許檔案
5. 不得順手修改無關功能
6. 任務完成後檢查：git status --short / git diff --name-only / git diff --stat
7. 小範圍任務完成後可 commit + push
8. commit 後必須更新 .agent/handoff_to_hermes.md
9. 若 Hermes 驗收失敗，下一輪必須優先修復該錯誤

---

## 三、Hermes 職責

Hermes 是驗收 Agent，負責：

1. 只驗收已 push 的 commit
2. 每次驗收前執行：git pull --ff-only
3. 驗證最新 commit 是否符合 handoff
4. 執行：flutter analyze / flutter test / 必要時 flutter build apk --release
5. 驗收完成後更新 .agent/hermes_review.md
6. 若驗收失敗，必須明確列出：失敗命令 / 錯誤訊息 / 建議修復檔案 / 是否允許 OpenClaw 自動修復

---

## 四、禁止事項

除非 Andy 明確批准，OpenClaw / Hermes 都不得執行：

- git reset / git stash / git pull 非 fast-forward merge
- 強制覆蓋檔案
- 修改 API key / 憑證 / package name / build / signing 設定
- 上傳 APK / 發布 / 部署
- 在驗收失敗時開新任務
- 同時處理多個任務

---

## 五、自動決策規則

### Hermes 驗收 PASS
OpenClaw 可繼續下一個任務。

### Hermes 驗收 FAIL
OpenClaw 下一輪必須優先修復 Hermes 指定錯誤，不可開新任務。

### git pull --ff-only 失敗
立即停止，回報 Andy，不得自行 merge / reset / stash。

### git status --short 出現非預期 modified
立即停止，回報 Andy，不得繼續。

### 任務修改超過 5 個檔案
立即停止，請 Andy 確認。

### 涉及核心設定（API key / 憑證 / .env / Android package name / signing config / build.gradle / pubspec.yaml 大幅改動 / Firebase notification 設定）
必須先請 Andy 確認。

---

## 六、交接檔案

- .agent/handoff_to_hermes.md — OpenClaw 完成任務後填寫
- .agent/hermes_review.md — Hermes 驗收後填寫
- .agent/agent_rules.md — 本規則檔
- .agent/current_status.md — 目前狀態
- .agent/task_queue.md — 任務佇列

---

## 七、lock 規則

若 .agent/lock.json 存在：
1. 代表有 Agent 正在執行任務
2. 另一個 Agent 不得修改 code
3. Hermes 可驗收已 push commit
4. OpenClaw 不可開新任務
5. 任務完成後必須刪除 lock

---

## 八、穩定基準

目前穩定基準以 origin/main 最新通過 Hermes 驗收的 commit 為準。

OpenClaw 不得覆蓋 Hermes 已驗收通過的 commit。
Hermes 不驗收未 commit / 未 push 的 WSL2 修改。
