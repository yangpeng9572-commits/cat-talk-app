# Hermes Windows Auto Review Script
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

# Run a command in the correct Windows directory.
# Key fix: psi.WorkingDirectory = $RepoPath ensures CMD starts in the right place,
# avoiding WSL UNC path inheritance that causes "CMD.EXE cannot access UNC path" errors.
function Run-InRepo {
    param([string]$exe, [string]$args, [string]$desc)
    $cmd = "$exe $args"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = '/c ' + $cmd
    $psi.WorkingDirectory = $RepoPath          # <-- critical: sets startup directory
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exit = $proc.ExitCode
    return @{
        ExitCode=$exit
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
$whereResult = Run-InRepo "where.exe" "flutter" "where flutter"
if ($whereResult.ExitCode -ne 0) {
    Write-Log "FAIL: where flutter failed (exit $($whereResult.ExitCode))"
    Write-Log "STDERR: $($whereResult.Stderr)"
    exit 1
}
$flutterOut = $whereResult.Stdout.Trim()
$flutterPaths = ($flutterOut -split "`r`n") | Where-Object { $_ -match "flutter\.exe" } | ForEach-Object { $_.Trim() }
if (-not $flutterPaths) {
    Write-Log "FAIL: Flutter not found in Windows PATH"
    Write-Log "where flutter output: $flutterOut"
    exit 1
}
$flutterExe = $flutterPaths[0]
Write-Log "Flutter found: $flutterExe"

$verResult = Run-InRepo "flutter" "--version" "flutter --version"
if ($verResult.ExitCode -ne 0) {
    Write-Log "FAIL: flutter --version failed (exit $($verResult.ExitCode))"
    exit 1
}
$verLine = ($verResult.Stdout -split "`r`n")[0]
Write-Log "Flutter version: $verLine"

# --- Working tree check ---
$wsResult = Run-InRepo "git" "-C `"$RepoPath`" status --porcelain" "git status"
if ($wsResult.ExitCode -ne 0) {
    Write-Log "ERROR: git status failed"
    exit 1
}
$ws = $wsResult.Stdout.Trim()
$modLines = ($ws -split "`r`n") + ($ws -split "`n") | Where-Object { $_ -match "^\s*[MR ]\s+" }
$badMods = $modLines | Where-Object {
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
$pullResult = Run-InRepo "git" "-C `"$RepoPath`" pull --ff-only origin main" "git pull"
if ($pullResult.ExitCode -ne 0) {
    Write-Log "ABORT: git pull failed (exit $($pullResult.ExitCode))"
    Write-Log "STDERR: $($pullResult.Stderr)"
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
$arResult = Run-InRepo "flutter" "analyze" "flutter analyze"
$sw.Stop()
$ac = $arResult.Stdout
$ac | Out-File -FilePath $ao -Encoding UTF8 -Force

if ($arResult.ExitCode -ne 0) {
    Write-Log "FAIL: flutter analyze (exit $($arResult.ExitCode))"
    if ($arResult.Stderr) { Write-Log "STDERR: $($arResult.Stderr)" }
    exit 1
}

$validOutput = $ac -match "No issues found" -or $ac -match "issues found" -or $ac -match "\d+\s+error" -or $ac -match "Analyzing" -or $ac -match "warning"
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
$ar = "0 errors ($in issues)"
Write-Log "flutter analyze: PASS ($ar, $($sw.Elapsed.TotalSeconds)s)"

# --- B. flutter test ---
$to = Join-Path $logsDir "flutter_test_auto.txt"
Write-Log "Running flutter test..."
$sw = [Diagnostics.Stopwatch]::StartNew()
$teResult = Run-InRepo "flutter" "test" "flutter test"
$sw.Stop()
$tc = $teResult.Stdout
$tc | Out-File -FilePath $to -Encoding UTF8 -Force

if ($teResult.ExitCode -ne 0) {
    Write-Log "FAIL: flutter test (exit $($teResult.ExitCode))"
    if ($teResult.Stderr) { Write-Log "STDERR: $($teResult.Stderr)" }
    exit 1
}

$validTest = $tc -match "All tests passed" -or $tc -match "\d+\s+tests?\s+passed" -or $tc -match "tests passed" -or $tc -match "test.*passed"
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
$blResult = Run-InRepo "flutter" "build apk --release" "flutter build"
$sw.Stop()
$bc = $blResult.Stdout
$bc | Out-File -FilePath $bo -Encoding UTF8 -Force

if ($blResult.ExitCode -ne 0) {
    Write-Log "FAIL: flutter build (exit $($blResult.ExitCode))"
    if ($blResult.Stderr) { Write-Log "STDERR: $($blResult.Stderr)" }
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
    Write-Log "FAIL: APK file not found at expected path: $bp"
    Write-Log "Build output: $($bc.Substring(0, [Math]::Min(500, $bc.Length)))"
    exit 1
}

# --- All PASS - update via Python ---
Write-Log "All checks passed -- updating .agent files..."
$py = Join-Path $RepoPath "scripts\_auto_review_update.py"
$resResult = Run-InRepo "python" "`"$py`" `"$RepoPath`" `"$ts`" `"$ch`" `"$ar`" `"$tp`" `"$bn`" `"$bp`"" "python update"
if ($resResult.ExitCode -ne 0) {
    Write-Log "ERROR: Python update failed (exit $($resResult.ExitCode))"
    Write-Log "STDERR: $($resResult.Stderr)"
    exit 1
}
Write-Log "Python: $($resResult.Stdout)"

# --- git add + commit + push ---
$gaResult = Run-InRepo "git" "-C `"$RepoPath`" add .agent\hermes_review.md .agent\handoff_to_hermes.md" "git add"
if ($gaResult.ExitCode -ne 0) { Write-Log "ERROR: git add failed"; exit 1 }
$gcResult = Run-InRepo "git" "-C `"$RepoPath`" commit -m `"docs: auto mark hermes validation pass`"" "git commit"
if ($gcResult.ExitCode -ne 0) { Write-Log "ERROR: git commit failed"; exit 1 }
$gpResult = Run-InRepo "git" "-C `"$RepoPath`" push" "git push"
if ($gpResult.ExitCode -ne 0) { Write-Log "ERROR: git push failed"; exit 1 }
Write-Log "git push: success"
Write-Log "Hermes Windows Auto Review END (PASS)"
Write-Log "========================================"
exit 0
