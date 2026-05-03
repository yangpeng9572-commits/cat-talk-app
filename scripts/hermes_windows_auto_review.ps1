param(
    [string]$RepoPath = "C:\Users\a0938\cat_talk_proper",
    [string]$LogFile  = "C:\Users\a0938\cat_talk_proper\logs\hermes_windows_auto_review.log"
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

# NOTE: $cmdArgs NOT $args -- avoids shadowing PowerShell's built-in $args automatic variable
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

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Log "========================================"
Write-Log "Hermes Windows Auto Review START"
Write-Log "Repo: $RepoPath"

if (-not (Test-Path $RepoPath)) {
    Write-Log "ERROR: Repo not found"
    exit 1
}

# --- A. Flutter PATH check ---
Write-Log "Checking Flutter PATH..."
$r = Run-InRepo "where.exe" "flutter" "where flutter"
if ($r.ExitCode -ne 0) {
    Write-Log "FAIL: where flutter failed (exit $($r.ExitCode))"
    Write-Log "STDERR: $($r.Stderr)"
    exit 1
}
$flutterOut = $r.Stdout.Trim()
$flutterPaths = ($flutterOut -split "`r`n") | Where-Object { $_ -match "flutter" } | ForEach-Object { $_.Trim() }
if (-not $flutterPaths) {
    Write-Log "FAIL: Flutter not found in Windows PATH"
    Write-Log "where flutter output: $flutterOut"
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

# --- Working tree check ---
$ws = Run-InRepo "git" "-C `"$RepoPath`" status --porcelain" "git status"
if ($ws.ExitCode -ne 0) {
    Write-Log "ERROR: git status failed"
    exit 1
}
$wsLines = ($ws.Stdout -split "`r`n") | Where-Object { $_ -match "^\s*[MR ]\s+" }
$badMods = $wsLines | Where-Object {
    $_ -notmatch "^\s*[MR ]\s+\.agent\\" -and
    $_ -notmatch "^\s*[MR ]\s+\.gitattributes" -and
    $_ -notmatch "^\s*[MR ]\s+\.gitignore"
}
if ($badMods) {
    Write-Log "ABORT: Working tree has modified app files:"
    $badMods | ForEach-Object { Write-Log "  $_" }
    Write-Log "OpenClaw must push or discard changes first."
    exit 0
}
Write-Log "Working tree clean"

# --- git pull ---
$pull = Run-InRepo "git" "-C `"$RepoPath`" pull --ff-only origin main" "git pull"
if ($pull.ExitCode -ne 0) {
    Write-Log "ABORT: git pull failed (exit $($pull.ExitCode))"
    Write-Log "STDERR: $($pull.Stderr)"
    exit 0
}
Write-Log "git pull: OK"

# --- Read handoff ---
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

# --- B. flutter analyze ---
$ao = Join-Path $logsDir "flutter_analyze_auto.txt"
Write-Log "Running flutter analyze..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$ar = Run-InRepo "flutter" "analyze" "flutter analyze"
$sw.Stop()
$ac = ($ar.Stderr + $ar.Stdout).Trim()
$ac | Out-File -FilePath $ao -Encoding UTF8 -Force

# flutter analyze: exit 1 = warnings/infos (OK), exit 2+ = real errors (FAIL)
if ($ar.ExitCode -ge 2) {
    Write-Log "FAIL: flutter analyze (exit $($ar.ExitCode))"
    Write-Log "Output: $($ac.Substring(0, [Math]::Min(500, $ac.Length)))"
    exit 1
}
$validOutput = $ac -match "No issues found" -or $ac -match "issues found" -or $ac -match "\d+\s+error" -or $ac -match "Analyzing"
if (-not $validOutput) {
    Write-Log "FAIL: flutter analyze output not recognized"
    Write-Log "Output: $($ac.Substring(0, [Math]::Min(500, $ac.Length)))"
    exit 1
}
$en = 0; if ($ac -match "(\d+)\s+errors?\s+found") { $en = [int]$matches[1] }
$in = 0; if ($ac -match "(\d+)\s+issues?\s+found") { $in = [int]$matches[1] }
if ($en -gt 0) {
    Write-Log "FAIL: flutter analyze found $en errors"
    exit 1
}
$arStr = "0 errors ($in issues)"
Write-Log "flutter analyze: PASS ($arStr, $($sw.Elapsed.TotalSeconds)s)"

# --- B. flutter test ---
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
    exit 1
}
$validTest = $tc -match "All tests passed" -or $tc -match "\d+\s+tests?\s+passed" -or $tc -match "tests passed"
if (-not $validTest) {
    Write-Log "FAIL: flutter test output not recognized"
    Write-Log "Output: $($tc.Substring(0, [Math]::Min(500, $tc.Length)))"
    exit 1
}
$tp = "N/A"
if ($tc -match "All tests passed") { $tp = "All passed" }
elseif ($tc -match "(\d+)\s+tests?\s+passed") { $tp = "$($matches[1]) passed" }
Write-Log "flutter test: PASS ($tp, $($sw.Elapsed.TotalSeconds)s)"

# --- B. flutter build ---
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
    exit 1
}
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
    }
    else {
        Write-Log "FAIL: APK exists but size is 0"
        exit 1
    }
}
else {
    Write-Log "FAIL: APK file not found at: $bp"
    Write-Log "Build output: $($bc.Substring(0, [Math]::Min(300, $bc.Length)))"
    exit 1
}

# --- All PASS - update via Python ---
Write-Log "All checks passed -- updating .agent files..."
$py = Join-Path $RepoPath "scripts\_auto_review_update.py"
$res = Run-InRepo "python" "`"$py`" `"$RepoPath`" `"$ts`" `"$ch`" `"$arStr`" `"$tp`" `"$bn`" `"$bp`"" "python update"
if ($res.ExitCode -ne 0) {
    Write-Log "ERROR: Python update failed (exit $($res.ExitCode))"
    Write-Log "STDERR: $($res.Stderr)"
    exit 1
}
Write-Log "Python: $($res.Stdout)"

# --- git add + commit + push ---
$ga = Run-InRepo "git" "-C `"$RepoPath`" add .agent\hermes_review.md .agent\handoff_to_hermes.md" "git add"
if ($ga.ExitCode -ne 0) { Write-Log "ERROR: git add failed"; exit 1 }
$gc = Run-InRepo "git" "-C `"$RepoPath`" commit -m `"docs: auto mark hermes validation pass`"" "git commit"
if ($gc.ExitCode -ne 0) { Write-Log "ERROR: git commit failed"; exit 1 }
$gp = Run-InRepo "git" "-C `"$RepoPath`" push" "git push"
if ($gp.ExitCode -ne 0) { Write-Log "ERROR: git push failed"; exit 1 }
Write-Log "git push: success"
Write-Log "Hermes Windows Auto Review END (PASS)"
Write-Log "========================================"
exit 0
