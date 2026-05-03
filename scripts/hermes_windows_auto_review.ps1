# Hermes Windows Auto Review Script
# Rules (2026-05-03):
#  1. Every round checks git status first.
#  2. If only logs/ or backup patch untracked, ignore.
#  3. If tracked modified: auto backup + restore (NO reset/stash/clean), then pull --ff-only.
#  4. If pull OK + handoff IDLE -> stop, report No waiting handoff.
#  5. If handoff WAITING_FOR_HERMES -> flutter analyze + test + (build if not SkipBuild).
#  6. If PASS -> update hermes_review.md (PASS), set handoff IDLE, commit + push.
#  7. If FAIL  -> update hermes_review.md (FAIL), keep handoff WAITING, commit + push.
#  8. Do NOT modify app code.
#  9. Do NOT reset/stash/revert/clean.
# 10. Do NOT upload APK unless Andy explicitly asks.

param(
    [string]$RepoPath = "C:\Users\a0938\cat_talk_proper",
    [string]$LogFile  = "C:\Users\a0938\cat_talk_proper\logs\hermes_windows_auto_review.log",
    [switch]$SkipBuild  # Quick Review: skip APK build to save time
)

$logsDir = Join-Path $RepoPath "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

function Write-Log {
    param([string]$m)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$stamp] $m" -Encoding UTF8
    Write-Host "[$stamp] $m"
}

# Run a command in the correct Windows directory.
# Uses WorkingDirectory to avoid WSL UNC path inheritance bug.
# Uses '/c ' (single quotes) to prevent PowerShell variable expansion.
function Run-InRepo {
    param([string]$exe, [string]$cmdArgs, [string]$desc)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = '/c ' + $exe + ' ' + $cmdArgs
    $psi.WorkingDirectory = $RepoPath
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{
        ExitCode=$proc.ExitCode
        Stdout=$stdout
        Stderr=$stderr
    }
}

function Read-Text {
    param([string]$p)
    if (Test-Path $p) { return Get-Content $p -Raw -Encoding UTF8 }
    return $null
}

function Get-ModifiedFiles {
    # Returns array of tracked modified file paths (relative), or $null if none.
    # Ignores .agent\, .gitattributes, .gitignore.
    $ws = Run-InRepo "git" "-C `"$RepoPath`" status --porcelain" "git status"
    if ($ws.ExitCode -ne 0) { return $null }
    $lines = ($ws.Stdout -split "`r`n") | Where-Object { $_ -match "^\s*[MR ]\s+" }
    $bad = $lines | Where-Object {
        $_ -notmatch "^\s*[MR ]\s+\.agent\\" -and
        $_ -notmatch "^\s*[MR ]\s+\.gitattributes" -and
        $_ -notmatch "^\s*[MR ]\s+\.gitignore"
    }
    if ($bad) {
        return ($bad | ForEach-Object { $_.TrimStart() -replace "^\s*[MR ]\s+", "" })
    }
    return @()
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Log "========================================"
Write-Log "Hermes Windows Auto Review START"
Write-Log "Repo: $RepoPath"

if (-not (Test-Path $RepoPath)) {
    Write-Log "ERROR: Repo not found"
    exit 1
}

# --- Rule 1 & 2: Check git status; ignore pure untracked (logs/, *.patch) ---
$wsRaw = Run-InRepo "git" "-C `"$RepoPath`" status --porcelain" "git status"
if ($wsRaw.ExitCode -ne 0) {
    Write-Log "ERROR: git status failed"
    exit 1
}
$wsRawTrim = $wsRaw.Stdout.Trim()

# Check for tracked modified files
$badMods = Get-ModifiedFiles

# --- Rule 3: If tracked modified, auto-backup then restore (NO reset/stash/clean) ---
if ($badMods -and $badMods.Count -gt 0) {
    Write-Log "ABORT: Working tree has modified files:"
    $badMods | ForEach-Object { Write-Log "  $_" }

    # Auto-backup
    $ts2 = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = Join-Path $RepoPath "windows_runner_dirty_before_restore_$ts2.patch"
    $backupRel = "windows_runner_dirty_before_restore_$ts2.patch"

    # Build file list for git diff
    $fileList = $badMods -join " "
    $diff = Run-InRepo "git" "-C `"$RepoPath`" diff -- $fileList" "git diff backup"
    if ($diff.ExitCode -eq 0 -and $diff.Stdout) {
        $diff.Stdout | Out-File -FilePath $backup -Encoding UTF8 -Force
        Write-Log "Backup saved: $backupRel"
    }
    else {
        Write-Log "WARNING: git diff backup failed (exit $($diff.ExitCode))"
    }

    # Restore tracked modified files to origin/main (NO reset/stash/clean)
    $restoreFiles = $badMods -join " "
    $restore = Run-InRepo "git" "-C `"$RepoPath`" restore -- $restoreFiles" "git restore"
    if ($restore.ExitCode -ne 0) {
        Write-Log "ERROR: git restore failed (exit $($restore.ExitCode))"
        Write-Log "STDERR: $($restore.Stderr)"
        exit 1
    }
    Write-Log "Restored: $restoreFiles"
}
else {
    Write-Log "Working tree clean (no tracked modifications)"
}

# --- git pull --ff-only ---
$pull = Run-InRepo "git" "-C `"$RepoPath`" pull --ff-only origin main" "git pull"
if ($pull.ExitCode -ne 0) {
    Write-Log "ABORT: git pull failed (exit $($pull.ExitCode))"
    Write-Log "STDERR: $($pull.Stderr)"
    exit 0
}
Write-Log "git pull: OK"

# --- Flutter PATH check ---
Write-Log "Checking Flutter PATH..."
$r = Run-InRepo "where.exe" "flutter" "where flutter"
if ($r.ExitCode -ne 0) {
    Write-Log "FAIL: where flutter failed (exit $($r.ExitCode))"
    exit 1
}
$flutterOut = $r.Stdout.Trim()
$flutterPaths = ($flutterOut -split "`r`n") | Where-Object { $_ -match "flutter" } | ForEach-Object { $_.Trim() }
if (-not $flutterPaths) {
    Write-Log "FAIL: Flutter not found in PATH"
    exit 1
}
$flutterExe = $flutterPaths[0]
Write-Log "Flutter found: $flutterExe"

$ver = Run-InRepo "flutter" "--version" "flutter --version"
if ($ver.ExitCode -ne 0) {
    Write-Log "FAIL: flutter --version failed (exit $($ver.ExitCode))"
    exit 1
}
Write-Log "Flutter version: $(($ver.Stdout -split "`r`n")[0])"

# --- Rule 4: Handoff IDLE -> stop ---
$hc = Read-Text (Join-Path $RepoPath ".agent\handoff_to_hermes.md")
if (-not $hc) {
    Write-Log "ERROR: handoff not found"
    exit 1
}
if ($hc -notmatch "Status:\s*WAITING_FOR_HERMES") {
    Write-Log "No waiting handoff. Stop."
    exit 0
}
Write-Log "Handoff is WAITING_FOR_HERMES -- starting validation"

$ch = "unknown"
if ($hc -match "Commit:\s*[`']([0-9a-f]+)[`']") { $ch = $matches[1] }
Write-Log "Target commit: $ch"

# ============================================================
# VALIDATION: flutter analyze + test + (build if not SkipBuild)
# ============================================================

$analyzePass = $false
$testPass    = $false
$buildPass   = $false

# --- flutter analyze ---
$ao = Join-Path $logsDir "flutter_analyze_auto.txt"
Write-Log "Running flutter analyze..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$ar = Run-InRepo "flutter" "analyze" "flutter analyze"
$sw.Stop()
$ac = ($ar.Stderr + $ar.Stdout).Trim()
$ac | Out-File -FilePath $ao -Encoding UTF8 -Force

# Accept exit 0 (clean) or exit 1 (warnings/info)
if ($ar.ExitCode -ge 2) {
    Write-Log "FAIL: flutter analyze (exit $($ar.ExitCode))"
    Write-Log "Output: $($ac.Substring(0, [Math]::Min(500, $ac.Length)))"
}
else {
    $validOut = $ac -match "No issues found" -or $ac -match "issues found" -or $ac -match "\d+\s+error" -or $ac -match "Analyzing"
    if (-not $validOut) {
        Write-Log "FAIL: flutter analyze output not recognized"
        Write-Log "Output: $($ac.Substring(0, [Math]::Min(500, $ac.Length)))"
    }
    else {
        $en = 0; if ($ac -match "(\d+)\s+errors?\s+found") { $en = [int]$matches[1] }
        $in = 0; if ($ac -match "(\d+)\s+issues?\s+found") { $in = [int]$matches[1] }
        if ($en -gt 0) {
            Write-Log "FAIL: flutter analyze found $en errors"
        }
        else {
            $arStr = "0 errors ($in issues)"
            Write-Log "flutter analyze: PASS ($arStr, $($sw.Elapsed.TotalSeconds)s)"
            $analyzePass = $true
        }
    }
}

# --- flutter test ---
$to = Join-Path $logsDir "flutter_test_auto.txt"
Write-Log "Running flutter test..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$te = Run-InRepo "flutter" "test" "flutter test"
$sw.Stop()
$tc = ($te.Stderr + $te.Stdout).Trim()
$tc | Out-File -FilePath $to -Encoding UTF8 -Force

if ($te.ExitCode -ne 0) {
    Write-Log "FAIL: flutter test (exit $($te.ExitCode))"
    if ($te.Stderr) { Write-Log "STDERR: $($te.Stderr)" }
}
else {
    $validTest = $tc -match "All tests passed" -or $tc -match "\d+\s+tests?\s+passed" -or $tc -match "tests passed"
    if (-not $validTest) {
        Write-Log "FAIL: flutter test output not recognized"
        Write-Log "Output: $($tc.Substring(0, [Math]::Min(500, $tc.Length)))"
    }
    else {
        $tp = "N/A"
        if ($tc -match "All tests passed") { $tp = "All passed" }
        elseif ($tc -match "(\d+)\s+tests?\s+passed") { $tp = "$($matches[1]) passed" }
        Write-Log "flutter test: PASS ($tp, $($sw.Elapsed.TotalSeconds)s)"
        $testPass = $true
    }
}

# --- flutter build (only for Full Build Review) ---
if (-not $SkipBuild) {
    $bo = Join-Path $logsDir "flutter_build_auto.txt"
    Write-Log "Running flutter build apk --release..."
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $bl = Run-InRepo "flutter" "build apk --release" "flutter build"
    $sw.Stop()
    $bc = $bl.Stdout
    $bc | Out-File -FilePath $bo -Encoding UTF8 -Force

    if ($bl.ExitCode -ne 0) {
        Write-Log "FAIL: flutter build (exit $($bl.ExitCode))"
        if ($bl.Stderr) { Write-Log "STDERR: $($bl.Stderr)" }
    }
    else {
        $bn = "N/A"; $bp = "N/A"
        if ($bc -match "Built .+\\app\\outputs\\flutter-apk\\(.+\.apk)") {
            $bn = $Matches[1]
            $bp = Join-Path $RepoPath "build\app\outputs\flutter-apk\$bn"
        }
        elseif ($bc -match "Built (.+\.apk)") {
            $bn = [IO.Path]::GetFileName($Matches[1])
            $bp = Join-Path $RepoPath "build\app\outputs\flutter-apk\$bn"
        }
        if ($bp -ne "N/A" -and (Test-Path $bp)) {
            $apkSize = (Get-Item $bp).Length
            if ($apkSize -gt 0) {
                Write-Log "flutter build: PASS ($bn, $($sw.Elapsed.TotalSeconds)s, $([Math]::Round($apkSize/1MB, 1))MB)"
                $buildPass = $true
            }
            else {
                Write-Log "FAIL: APK exists but size is 0"
            }
        }
        else {
            Write-Log "FAIL: APK file not found at: $bp"
        }
    }
}
else {
    $bn = "SKIPPED"; $bp = "SKIPPED"
    $buildPass = $true  # SkipBuild mode: build doesn't block
    Write-Log "flutter build: SKIPPED (Quick Review mode)"
}

# ============================================================
# Rule 6 & 7: Update .agent files based on validation result
# ============================================================

$allPass = $analyzePass -and $testPass -and $buildPass
$py = Join-Path $RepoPath "scripts\_auto_review_update.py"

if ($allPass) {
    Write-Log "All checks passed -- updating .agent files..."
    $res = Run-InRepo "python" "`"$py`" `"$RepoPath`" `"$ts`" `"$ch`" `"$arStr`" `"$tp`" `"$bn`" `"$bp`"" "python update"
    if ($res.ExitCode -ne 0) {
        Write-Log "ERROR: Python update failed (exit $($res.ExitCode))"
        Write-Log "STDERR: $($res.Stderr)"
        exit 1
    }
    Write-Log "Python: $($res.Stdout)"
}
else {
    Write-Log "Validation FAILED -- updating hermes_review.md with FAIL..."
    $failReason = "analyze=$analyzePass test=$testPass build=$buildPass"
    $res = Run-InRepo "python" "`"$py`" `"$RepoPath`" `"$ts`" `"$ch`" `"FAIL($failReason)`" `"FAIL`" `"$bn`" `"$bp`"" "python update"
    if ($res.ExitCode -ne 0) {
        Write-Log "ERROR: Python update failed (exit $($res.ExitCode))"
        exit 1
    }
    Write-Log "Python: $($res.Stdout)"
}

# --- git add + commit + push ---
$ga = Run-InRepo "git" "-C `"$RepoPath`" add .agent\hermes_review.md .agent\handoff_to_hermes.md" "git add"
if ($ga.ExitCode -ne 0) { Write-Log "ERROR: git add failed"; exit 1 }

$commitMsg = if ($allPass) { "docs: auto mark hermes validation pass" } else { "docs: auto mark hermes validation FAIL" }
$gc = Run-InRepo "git" "-C `"$RepoPath`" commit -m `"$commitMsg`"" "git commit"
if ($gc.ExitCode -ne 0) { Write-Log "ERROR: git commit failed"; exit 1 }

$gp = Run-InRepo "git" "-C `"$RepoPath`" push" "git push"
if ($gp.ExitCode -ne 0) { Write-Log "ERROR: git push failed"; exit 1 }
Write-Log "git push: success"

if ($allPass) {
    Write-Log "Hermes Windows Auto Review END (PASS)"
}
else {
    Write-Log "Hermes Windows Auto Review END (FAIL)"
}
Write-Log "========================================"
exit 0
