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

---

## OpenClaw Preflight Gate Rules

每輪自動研發開始前，必須先執行「前置狀態檢查」。不得跳過。不得直接開始新任務。

### 一、每輪開始必做

每輪開始時，請先執行：

```bash
cd /home/a0938/cat_talk_proper
git status --short
git pull --ff-only
git status --short
git diff --name-only
git diff --stat
cat .agent/handoff_to_hermes.md
cat .agent/hermes_review.md
cat .agent/task_queue.md
git log --oneline -8
```

### 二、第一優先判斷：handoff

若 `.agent/handoff_to_hermes.md` 顯示：
- `Status: WAITING_FOR_HERMES` 或 `Waiting for Hermes: YES`

你必須立即停止新任務。

**此時只允許：**
1. 回報目前等待 Hermes 驗收的 task / commit
2. 回報 git status
3. 等待 Hermes 驗收
4. 若 Hermes Review 是 FAIL，才可修指定錯誤

**此時禁止：**
1. 開始新任務
2. 修改 app code
3. commit 新 app 變更
4. push 新 app commit
5. 開始下一批 batch
6. 更新 task_queue 為新任務進度

### 三、第二優先判斷：Hermes Review

若 `.agent/hermes_review.md` 顯示 `Result: FAIL`：

你不得開始新任務。

你只能：
1. 讀取 Hermes Review 的錯誤
2. 只修 Hermes 指定的錯誤
3. 只修改 Hermes 允許的檔案
4. 修復後 commit + push
5. 更新 handoff_to_hermes.md 為 WAITING_FOR_HERMES
6. 停止，等待 Hermes 重新驗收

### 四、第三優先判斷：工作樹是否乾淨

若 `git status --short` 顯示任何 modified / untracked 檔案：

你不得開始新任務。

你必須先做「本地未提交修改盤點」，並回報：

1. modified 檔案完整清單
2. untracked 新檔案完整清單
3. git diff --name-only
4. git diff --stat
5. 每個檔案修改摘要
6. 這些修改屬於哪個任務
7. 是否已完成可 commit
8. 是否有非預期修改
9. 建議下一步（commit / 拆分 / 放棄 / 等待 Andy 確認）

在 Andy 確認前，不得：開新任務、commit、push、reset、stash、revert、checkout。

### 五、只有以下條件同時成立，才可開始新任務

只有當以下**全部成立**時，才可以依 task_queue.md 選下一個任務：

1. handoff_to_hermes.md 是 `IDLE`
2. `Waiting for Hermes` 是 `NO`
3. hermes_review.md 最新 `Result` 是 `PASS`
4. git status --short 乾淨
5. 沒有 modified 檔案
6. 沒有 untracked 任務檔案
7. 沒有 `.agent/lock.json`
8. 沒有 Hermes FAIL 等待修復

若以上任一條不成立，請停止並回報原因。

### 六、開始任務後的規則

若符合條件可以開始新任務：
1. 只能選 task_queue.md 中最高優先且範圍清楚的一個任務
2. 每輪只處理一個任務
3. 不得同時做多個 batch
4. 不得順手修其他問題
5. 若預計修改超過 5 個檔案，必須先停止回報 Andy
6. 若需要修改允許範圍外檔案，必須先停止回報 Andy

### 七、任務完成後固定流程

若本輪有修改 app code：

1. 執行：`git status --short` / `git diff --name-only` / `git diff --stat`
2. 確認只修改本任務相關檔案
3. commit + push app code
4. 更新 `.agent/handoff_to_hermes.md`：
   - `Status: WAITING_FOR_HERMES`
   - `Waiting for Hermes: YES`
   - Task ID / Task name / Commit hash / Modified files / Required Hermes actions
5. commit + push handoff
6. 停止，不得繼續下一個任務

### 八、若本輪沒有修改

若本輪只是分析，沒有修改任何檔案：
1. 回報 NO_CODE_CHANGE
2. 不要建立 handoff
3. 不要要求 Hermes 驗收
4. 不要 commit / push
5. 下一輪仍需重新做前置檢查

### 九、永久禁止事項

除非 Andy 明確批准，不得執行：
1. git reset / git stash / git revert / git checkout / git clean
2. git pull 非 fast-forward merge
3. 修改 build / signing / package / API key
4. 上傳 APK / 發布
5. handoff 是 WAITING_FOR_HERMES 時繼續開發
6. Hermes Review 是 FAIL 時開新任務

### 十、每輪回報格式

每輪固定回報：
1. handoff 狀態
2. hermes_review 狀態
3. git status 是否乾淨
4. 是否有 modified
5. 是否有 untracked
6. 是否允許開新任務
7. 若不允許，原因
8. 若允許，本輪選擇任務
9. 修改檔案
10. commit hash
11. handoff 是否已更新
12. 是否等待 Hermes 驗收
