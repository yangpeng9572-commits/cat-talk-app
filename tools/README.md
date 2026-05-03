# Cat Talk Agent War Room 🦞 vs 🤖

即時監控 OpenClaw / Hermes 雙 Agent 協作狀態的 Web Dashboard。

## 用途

- 即時顯示 OpenClaw / Hermes 角色狀態
- 顯示 handoff 進度、驗收結果
- 顯示最近 commits、Cron 執行歷史
- 判斷 OpenClaw 是否可以繼續下一個任務
- 遊戲風格 HUD 介面，角色會動

## 啟動方式

```bash
cd /home/a0938/.openclaw/workspace/tools/agent_monitor
python3 app.py
```

## 本機網址

- Dashboard：http://127.0.0.1:8787/
- 狀態 API：http://127.0.0.1:8787/api/status
- 健康檢查：http://127.0.0.1:8787/api/health

## 功能特色

### 角色動畫（CSS only，無需圖片）

**OpenClaw 🦞**
| 狀態 | 動畫 |
|------|------|
| Idle | 輕微上下浮動 |
| Waiting Hermes | 金色 pulse |
| Working | 快速 pulse + 鍵盤閃爍 |
| Ready | 綠色 glow |
| Blocked | 紅色警告閃動 |

**Hermes 🤖**
| 狀態 | 動畫 |
|------|------|
| Idle | 待機浮動 |
| Reviewing | 掃描藍光 |
| PASS | 綠色彈跳 + glow |
| FAIL | 紅色震動 |

### 自動刷新
- 每 5 秒自動 fetch `/api/status`
- 不會整頁刷新，只更新內容
- 斷線時顯示「Connection lost」提示

### 響應式
- 手機版可正常觀看
- 卡片式佈局自動堆疊

## API 路徑

| Method | 路徑 | 說明 |
|--------|------|------|
| GET | `/` | Dashboard 頁面 |
| GET | `/api/health` | 健康檢查 |
| GET | `/api/status` | 完整 Agent 狀態 JSON |

## /api/status 欄位

```json
{
  "current_time": "2026-05-03T...",
  "repo_path": "/home/a0938/cat_talk_proper",
  "git_status": { "is_clean": true/false },
  "recent_commits": [...],
  "handoff_status": "IDLE | WAITING_FOR_HERMES",
  "waiting_for_hermes": true/false,
  "hermes_review_result": "PASS | FAIL",
  "latest_review_task": "...",
  "can_openclaw_continue": true/false,
  "decision_text": "...",
  "recent_cron_runs_raw": "..."
}
```

## 安全限制

- ✅ 只讀模式，不修改任何檔案
- ✅ 不執行 git pull / fetch
- ✅ 不執行 git add / commit / push
- ✅ 不執行 reset / stash
- ✅ 不修改 repo 內任何檔案
- ✅ 只從外部讀取狀態資料

## 資料來源

- Repo：`/home/a0938/cat_talk_proper`
- `.agent/handoff_to_hermes.md`
- `.agent/hermes_review.md`
- `git status --short`
- `git log --oneline -8`
- `openclaw cron list`
- `openclaw cron runs --limit 10`