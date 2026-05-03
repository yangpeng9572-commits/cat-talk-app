<#
.SYNOPSIS
    Hermes Windows Auto Review Script
    Cat Talk 自動驗收腳本 — 由 Windows Task Scheduler 定期執行
.DESCRIPTION
    每 6~10 分鐘檢查 handoff 狀態，若為 WAITING_FOR_HERMES 則執行驗收流程。
    驗收通過：更新 hermes_review.md + handoff_to_hermes.md → IDLE，commit + push
    驗收失敗：更新 hermes_review.md → FAIL，commit + push（handoff 維持 WAITING）
.NOTES
    請勿手動修改 .agent 檔案，否則自動驗收可能覆寫。
#>

param(
    [string]$RepoPath = "C:\Users\a0938\cat_talk_proper",
    [string]$LogFile = "C:\Users\a0938\cat_talk_proper\logs\hermes_windows_auto_review.log"
)

# ============================================================
# 函式：寫 Log
# ============================================================
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logLine -Encoding UTF8
    Write-Host $logLine
}

# ============================================================
# 函式：執行 git 命令並檢查結果
# ============================================================
function Invoke-GitCommand {
    param([string]$Args, [string]$Description)
    $result = git -C $RepoPath $Args 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        Write-Log "ERROR: $Description failed (exit $exitCode): $result"
        return $null
    }
    return $result
}

# ============================================================
# 函式：讀取文字檔（UTF-8）
# ============================================================
function Read-FileContent {
    param([string]$Path)
    if (Test-Path $Path) {
        return Get-Content $Path -Raw -Encoding UTF8
    }
    return $null
}

# ============================================================
# 函式：寫入文字檔（UTF-8）
# ============================================================
function Write-FileContent {
    param([string]$Path, [string]$Content)
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

# ============================================================
# 函式：更新 hermes_review.md（通過）
# ============================================================
function Update-HermesReview-Pass {
    param([string]$CommitHash, [string]$AnalyzedErrors, [string]$TestPassed, [string]$BuildResult, [string]$APKPath, [string]$Timestamp)

    $reviewPath = Join-Path $RepoPath ".agent\hermes_review.md"
    $content = Read-FileContent $reviewPath
    if ($null -eq $content) {
        Write-Log "ERROR: hermes_review.md not found"
        return $false
    }

    # 解析 Task ID
    $taskId = "P0-5"
    if ($content -match "- Task ID: (.+)") { $taskId = $matches[1].Trim() }
    if ($content -match "Task IDs?: (.+)") {
        $taskId = $matches[1] -replace "`n|\|\*", " "
        $taskId = ($taskId -split "\r?\n")[0].Trim()
    }

    # 更新 Current Review Status
    $content = $content -replace "(?m)^- Result: .+$", "- Result: PASS"
    $content = $content -replace "(?m)^- Waiting for OpenClaw fix: .+$", "- Waiting for OpenClaw fix: NO"
    $content = $content -replace "(?m)^- Last reviewed by: .+$", "- Last reviewed by: Hermes Windows Auto Review"
    $content = $content -replace "(?m)^- Last reviewed at: .+$", "- Last reviewed at: $Timestamp"

    # 在 Reviewed Tasks 最前面插入本輪驗收（置換「本輪驗收」區塊）
    $newEntry = @"

### 本輪驗收：$taskId（Hermes Windows Auto Review 執行）
- Commit: ``$CommitHash``
- Status: **PASS**

**驗收結果：**
- ✅ Flutter analyze：PASS（$AnalyzedErrors）
- ✅ Flutter test：PASS（$TestPassed）
- ✅ Flutter build apk --release：PASS（$BuildResult）
- ✅ APK path：$APKPath
- ✅ git status：CLEAN（auto review 僅修改 .agent 檔）

"@

    # 置換現有「本輪驗收」為「上輪驗收」
    if ($content -match "(?ms)(### 本輪驗收.+?)(\n### 上輪驗收)") {
        $content = $content -replace "(?ms)(### 本輪驗收.+?)(\n### 上輪驗收)", "`$1`$2"
    }
    $content = $content -replace "(?ms)(\n## 歷史任務摘要\n)", "${newEntry}`$1"

    # 更新歷史任務摘要表格
    $newTableRow = "| AutoReview-$taskId | ``$CommitHash`` | PASS | $Timestamp |"
    if ($content -notmatch [regex]::Escape($newTableRow)) {
        $content = $content -replace "(?m)^(\| Task \| Commit \|)", "| AutoReview-$taskId | ``$CommitHash`` | PASS | $Timestamp |`n`$1"
    }

    Write-FileContent $reviewPath $content
    Write-Log "Updated hermes_review.md → PASS"
    return $true
}

# ============================================================
# 函式：更新 hermes_review.md（失敗）
# ============================================================
function Update-HermesReview-Fail {
    param([string]$CommitHash, [string]$FailedCommand, [string]$ErrorOutput, [string]$Timestamp)

    $reviewPath = Join-Path $RepoPath ".agent\hermes_review.md"
    $content = Read-FileContent $reviewPath
    if ($null -eq $content) {
        Write-Log "ERROR: hermes_review.md not found"
        return $false
    }

    $taskId = "P0-5"
    if ($content -match "- Task ID: (.+)") { $taskId = $matches[1].Trim() }
    if ($content -match "Task IDs?: (.+)") {
        $taskId = $matches[1] -replace "`n|\|\*", " "
        $taskId = ($taskId -split "\r?\n")[0].Trim()
    }

    $content = $content -replace "(?m)^- Result: .+$", "- Result: FAIL"
    $content = $content -replace "(?m)^- Waiting for OpenClaw fix: .+$", "- Waiting for OpenClaw fix: YES"
    $content = $content -replace "(?m)^- Last reviewed by: .+$", "- Last reviewed by: Hermes Windows Auto Review"
    $content = $content -replace "(?m)^- Last reviewed at: .+$", "- Last reviewed at: $Timestamp"

    $errorSnip = if ($ErrorOutput.Length -gt 300) { $ErrorOutput.Substring(0, 300) + "..." } else { $ErrorOutput }

    $newEntry = @"

### 本輪驗收：$taskId（Hermes Windows Auto Review 執行）
- Commit: ``$CommitHash``
- Status: **FAIL**

**失敗原因：**
- Failed command：$FailedCommand
- Error：$errorSnip

"@

    if ($content -match "(?ms)(### 本輪驗收.+?)(\n### 上輪驗收)") {
        $content = $content -replace "(?ms)(### 本輪驗收.+?)(\n### 上輪驗收)", "`$1`$2"
    }
    $content = $content -replace "(?ms)(\n## 歷史任務摘要\n)", "${newEntry}`$1"

    $newTableRow = "| AutoReview-$taskId | ``$CommitHash`` | FAIL | $Timestamp |"
    if ($content -notmatch [regex]::Escape($newTableRow)) {
        $content = $content -replace "(?m)^(\| Task \| Commit \|)", "| AutoReview-$taskId | ``$CommitHash`` | FAIL | $Timestamp |`n`$1"
    }

    Write-FileContent $reviewPath $content
    Write-Log "Updated hermes_review.md → FAIL"
    return $true
}

# ============================================================
# 函式：更新 handoff_to_hermes.md（IDLE）
# ============================================================
function Update-Handoff-Idle {
    param([string]$Timestamp)

    $handoffPath = Join-Path $RepoPath ".agent\handoff_to_hermes.md"
    $content = Read-FileContent $handoffPath
    if ($null -eq $content) {
        Write-Log "ERROR: handoff_to_hermes.md not found"
        return $false
    }

    $content = $content -replace "(?m)^- Status: .+$", "- Status: IDLE"
    $content = $content -replace "(?m)^- Waiting for Hermes: .+$", "- Waiting for Hermes: NO"
    $content = $content -replace "(?m)^- Last updated by: .+$", "- Last updated by: Hermes Windows Auto Review"
    $content = $content -replace "(?m)^- Last updated at: .+$", "- Last updated at: $Timestamp"

    Write-FileContent $handoffPath $content
    Write-Log "Updated handoff_to_hermes.md → IDLE"
    return $true
}

# ============================================================
# 主程式
# ============================================================

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Log "========================================"
Write-Log "Hermes Windows Auto Review START"

# 0. 確認 repo 路徑
if (-not (Test-Path $RepoPath)) {
    Write-Log "ERROR: Repo path not found: $RepoPath"
    exit 1
}
Set-Location $RepoPath
Write-Log "Repo: $RepoPath"

# 0b. 確保 logs 目錄存在
$logsDir = Join-Path $RepoPath "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

# 0c. 檢查工作樹是否有 modified app code（.dart/.yaml/.json/.gradle 等）
$workingStatus = Invoke-GitCommand "status --porcelain"
if ($null -eq $workingStatus) {
    Write-Log "ERROR: git status failed"
    exit 1
}
# 過濾掉 .agent 檔案的 modified（這些是預期的）
$appModified = $workingStatus -split "`n" | Where-Object {
    $_ -match "^\s*[MR]\s+" -and
    $_ -notmatch "^\s*[MR]\s+\.agent\\" -and
    $_ -notmatch "^\s*[MR]\s+\.gitattributes" -and
    $_ -notmatch "^\s*[MR]\s+\.gitignore"
}
if ($appModified) {
    Write-Log "ABORT: Working tree has modified app files:"
    $appModified | ForEach-Object { Write-Log "  $_" }
    Write-Log "Stop. OpenClaw must push or discard changes first."
    exit 0
}
Write-Log "Working tree clean (only .agent files may differ)"

# 1. git pull
Write-Log "git pull --ff-only..."
$pullResult = Invoke-GitCommand "pull --ff-only origin main"
if ($null -eq $pullResult) {
    Write-Log "ABORT: git pull failed. Working tree may have conflicts. No action taken."
    exit 0
}
Write-Log "git pull: $pullResult"

# 2. 讀取 handoff 狀態
$handoffPath = Join-Path $RepoPath ".agent\handoff_to_hermes.md"
$handoffContent = Read-FileContent $handoffPath
if ($null -eq $handoffContent) {
    Write-Log "ERROR: handoff_to_hermes.md not found"
    exit 1
}

# 3. 檢查是否 WAITING_FOR_HERMES
if ($handoffContent -notmatch "Status:\s*WAITING_FOR_HERMES") {
    Write-Log "No waiting handoff (Status != WAITING_FOR_HERMES). Stop."
    Write-Log "Hermes Windows Auto Review END"
    exit 0
}
Write-Log "Handoff is WAITING_FOR_HERMES — starting validation"

# 4. 讀取 handoff 中的 commit hash
$commitHash = "unknown"
if ($handoffContent -match "Commit:\s*[`']([0-9a-f]+)[`']") {
    $commitHash = $matches[1]
}
Write-Log "Target commit: $commitHash"

# 5. 執行 flutter analyze
$analyzeOut = Join-Path $logsDir "flutter_analyze_auto.txt"
Write-Log "Running flutter analyze..."
$start = Get-Date
$analyzeProcess = Start-Process -FilePath "flutter" -ArgumentList "analyze" -WorkingDirectory $RepoPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $analyzeOut -RedirectStandardError $analyzeOut
$analyzeExit = $analyzeProcess.ExitCode
$analyzeDuration = (Get-Date) - $start

if ($analyzeExit -ne 0) {
    Write-Log "FAIL: flutter analyze failed (exit $analyzeExit)"
    Update-HermesReview-Fail -CommitHash $commitHash -FailedCommand "flutter analyze" -ErrorOutput "flutter analyze exit $analyzeExit" -Timestamp $timestamp
    Invoke-GitCommand "add .agent\hermes_review.md"
    Invoke-GitCommand "commit -m `"docs: auto mark hermes validation fail`""
    Invoke-GitCommand "push"
    Write-Log "Hermes Windows Auto Review END (FAIL)"
    exit 0
}

# 解析 analyze 結果
$analyzeContent = Read-FileContent $analyzeOut
$errorCount = 0
if ($analyzeContent -match "(\d+) errors? found") {
    $errorCount = [int]$matches[1]
}
$issueCount = 0
if ($analyzeContent -match "(\d+) issues? found") {
    $issueCount = [int]$matches[1]
}
$analyzeResult = "0 errors ($issueCount issues)"
Write-Log "flutter analyze: PASS ($analyzeResult, ${analyzeDuration.TotalSeconds}s)"

# 6. 執行 flutter test
$testOut = Join-Path $logsDir "flutter_test_auto.txt"
Write-Log "Running flutter test..."
$start = Get-Date
$testProcess = Start-Process -FilePath "flutter" -ArgumentList "test" -WorkingDirectory $RepoPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $testOut -RedirectStandardError $testOut
$testExit = $testProcess.ExitCode
$testDuration = (Get-Date) - $start

if ($testExit -ne 0) {
    Write-Log "FAIL: flutter test failed (exit $testExit)"
    Update-HermesReview-Fail -CommitHash $commitHash -FailedCommand "flutter test" -ErrorOutput "flutter test exit $testExit" -Timestamp $timestamp
    Invoke-GitCommand "add .agent\hermes_review.md"
    Invoke-GitCommand "commit -m `"docs: auto mark hermes validation fail`""
    Invoke-GitCommand "push"
    Write-Log "Hermes Windows Auto Review END (FAIL)"
    exit 0
}
$testContent = Read-FileContent $testOut
$testPassed = "N/A"
if ($testContent -match "(\d+) tests? passed!") {
    $testPassed = "$($matches[1]) passed"
} elseif ($testContent -match "All tests passed!") {
    $testPassed = "All passed"
}
Write-Log "flutter test: PASS ($testPassed, ${testDuration.TotalSeconds}s)"

# 7. 執行 flutter build apk --release
$buildOut = Join-Path $logsDir "flutter_build_auto.txt"
Write-Log "Running flutter build apk --release..."
$start = Get-Date
$buildProcess = Start-Process -FilePath "flutter" -ArgumentList "build apk --release" -WorkingDirectory $RepoPath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $buildOut -RedirectStandardError $buildOut
$buildExit = $buildProcess.ExitCode
$buildDuration = (Get-Date) - $start

if ($buildExit -ne 0) {
    Write-Log "FAIL: flutter build apk --release failed (exit $buildExit)"
    Update-HermesReview-Fail -CommitHash $commitHash -FailedCommand "flutter build apk --release" -ErrorOutput "flutter build apk --release exit $buildExit" -Timestamp $timestamp
    Invoke-GitCommand "add .agent\hermes_review.md"
    Invoke-GitCommand "commit -m `"docs: auto mark hermes validation fail`""
    Invoke-GitCommand "push"
    Write-Log "Hermes Windows Auto Review END (FAIL)"
    exit 0
}

$buildContent = Read-FileContent $buildOut
$buildResult = "SUCCESS"
$apkPath = "N/A"
if ($buildContent -match "Built .+\\app\\outputs\\flutter-apk\\(.+\.apk)") {
    $buildResult = "SUCCESS ($($Matches[1]))"
    $apkPath = "build\app\outputs\flutter-apk\$($Matches[1])"
} elseif ($buildContent -match "Built (.+\.apk)") {
    $m = [regex]::Match($buildContent, "Built (.+\.apk)")
    $apkName = Split-Path $m.Groups[1].Value -Leaf
    $buildResult = "SUCCESS ($apkName)"
    $apkPath = "build\app\outputs\flutter-apk\$apkName"
}
Write-Log "flutter build apk --release: PASS ($buildResult, ${buildDuration.TotalSeconds}s)"

# 8. 全部通過 → 更新檔案
Write-Log "All checks passed — updating .agent files"
Update-HermesReview-Pass -CommitHash $commitHash -AnalyzedErrors $analyzeResult -TestPassed $testPassed -BuildResult $buildResult -APKPath $apkPath -Timestamp $timestamp
Update-Handoff-Idle -Timestamp $timestamp

# 9. git add + commit + push
$addResult = Invoke-GitCommand "add .agent\hermes_review.md .agent\handoff_to_hermes.md"
if ($null -eq $addResult) {
    Write-Log "ERROR: git add failed"
    exit 1
}

$commitResult = Invoke-GitCommand "commit -m `"docs: auto mark hermes validation pass`""
if ($null -eq $commitResult) {
    Write-Log "ERROR: git commit failed"
    exit 1
}

$pushResult = Invoke-GitCommand "push"
if ($null -eq $pushResult) {
    Write-Log "ERROR: git push failed"
    exit 1
}

Write-Log "git push: success"
Write-Log "Hermes Windows Auto Review END (PASS)"
Write-Log "========================================"
exit 0
