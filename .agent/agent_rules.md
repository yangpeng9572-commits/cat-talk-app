# Cat Talk / 喵心語 — OpenClaw 自動化作業規則

> 本檔案是 OpenClaw 每次 cron job 啟動時的唯一任務規則來源。
> mempalace 離線期間，不得依賴任何過去 session 的記憶。
> 所有規則、任務狀態、允許修改的檔案，都必須從本檔案 + .agent/*.md 重新讀取。

---

## 協作架構（不變）

| 動作 | OpenClaw (WSL2) | Hermes (Windows) |
|------|----------------|-----------------|
| git commit + push | ✅ | ❌ |
| flutter analyze / test | ✅ | ✅ |
| flutter build apk | ❌ | ✅ |
| APK 上傳 Google Drive | ❌ | ✅ |

---

## Preflight Check（每輪必須執行）

每次 cron job 啟動，OpenClaw 必須先執行：

```bash
cd /home/a0938/cat_talk_proper
git status --short
git pull --ff-only
cat .agent/handoff_to_hermes.md
cat .agent/hermes_review.md
cat .agent/task_queue.md
```

### 優先判斷順序

1. **handoff 是 WAITING_FOR_HERMES？** → 立即停止，等待 Hermes 驗收
2. **hermes_review 是 FAIL？** → 只修 Hermes 指定的錯誤
3. **有 modified/untracked 檔案？** → 盤點後回報，不得擅自 commit
4. **以上皆非** → 從 task_queue.md 選下一個最高優先任務

---

## 每輪開始時的回報格式

```
【任務開始】
任務名稱：
允許修改的檔案：
禁止修改的檔案：
git status：
mempalace 離線：YES（本次任務不得依賴長期記憶）
已讀取 agent_rules.md：YES
```

---

## 允許執行的動作

- ✅ git status / git log
- ✅ git commit（每次須符合 handoff 格式）
- ✅ git push
- ✅ flutter analyze / flutter test
- ✅ 讀取任何檔案
- ✅ 修復 flutter analyze 的 **error**（只看 error，不主動修 warning/info）
- ✅ 寫入 .agent/*.md（同步任務狀態）
- ✅ 小範圍修復（限本任務相關、限明確的 error）

---

## 永久禁止事項

- ❌ git pull / fetch（非 ff-only 的 merge / rebase / reset / stash）
- ❌ 修改 API key / 憑證 / package name / build.gradle / signing
- ❌ 大重構（不給 code 的前提下不準動架構）
- ❌ 上傳 APK / 發布 / 部署
- ❌ 跨任務混改（每輪只選一個任務）
- ❌ 修改超過 5 個檔案（要先回報 Andy）
- ❌ 在 handoff=WAITING_FOR_HERMES 時繼續開發
- ❌ 在 hermes_review=FAIL 時開新任務

---

## 任務允許範圍

每輪只準修改**任務指定的檔案**。

- 若需要修改不在允許清單的檔案 → 立即停止，回報 Andy
- 若發現明顯相關的編譯錯誤 → 限該檔案、限 error 等級，不順手「優化」
- error 修復後立即執行 `flutter analyze --no-pub` 驗證

---

## 任務完成後的回報格式

```
【任務完成】
修改的檔案：
修改原因：
flutter analyze 結果：（errors N, warnings N）
flutter test 結果：（如有執行）
git status：
是否有未授權檔案異動：（YES/NO）
建議交給 Hermes 驗收：（YES/NO）
下一輪建議任務：
```

---

## 交接流程

1. 任務完成 → commit + push
2. 更新 `.agent/handoff_to_hermes.md`（Status: WAITING_FOR_HERMES, Waiting for Hermes: YES）
3. commit + push handoff 檔案
4. 停止，等待 Hermes 驗收

若 Hermes PASS → 下一輪可選新任務
若 Hermes FAIL → 只修 Hermes 指定的錯誤，不可開新任務

---

## mempalace 離線期間的特別規則

mempalace MCP server 目前處於離線狀態（mempalace 路徑已修復，但 MCP 連線仍會中斷）。

**每輪視同全新 session**：所有規則從 .agent/*.md 讀取，不依赖任何外部記憶。

---

## 與 Hermes 的分工（不變）

- **OpenClaw**：在 WSL2 完成開發 → commit → push
- **Hermes**：在 Windows pull --ff-only → flutter analyze/test/build → 驗收回報
- OpenClaw 不得覆蓋 Hermes 已驗收通過的 commit
- Hermes 不驗收未 commit/push 的 WSL2 修改
