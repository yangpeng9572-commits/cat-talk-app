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

function Run-Cmd {
    param([string]$cmd)
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "cmd.exe"
    $pinfo.Arguments = "/c cd /d `"$RepoPath`" && $cmd"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $stdout = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { return $null }
    return $stdout
}

function Run-Flutter {
    param([string]$args, [string]$outFile)
    Write-Log "Running flutter $args..."
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "cmd.exe"
    $pinfo.Arguments = "/c cd /d `"$RepoPath`" && flutter $args"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $p.Start() | Out-Null
    $p.WaitForExit()
    $sw.Stop()
    $out = $p.StandardOutput.ReadToEnd()
    if ($p.ExitCode -ne 0) {
        $err = $p.StandardError.ReadToEnd()
        Write-Log "FAIL: flutter $args (exit $($p.ExitCode))"
        if ($err) { Write-Log "STDERR: $err" }
        exit 1
    }
    $out | Out-File -FilePath $outFile -Encoding UTF8 -Force
    return @{Output=$out; Seconds=$sw.Elapsed.TotalSeconds}
}

function Read-Text {
    param([string]$p)
    if (Test-Path $p) { return Get-Content $p -Raw -Encoding UTF8 }
    return $null
}

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Log "========================================"
Write-Log "Hermes Windows Auto Review START"

if (-not (Test-Path $RepoPath)) { Write-Log "ERROR: Repo not found"; exit 1 }

# Working tree check
$ws = Run-Cmd "git status --porcelain"
if ($null -eq $ws) { Write-Log "ERROR: git status failed"; exit 1 }
$allLines = ($ws -split "`r`n") + ($ws -split "`n") | Where-Object { $_ -match "^\s*[MR]\s+" }
$bad = $allLines | Where-Object {
    $_ -notmatch "^\s*[MR]\s+\.agent\\" -and
    $_ -notmatch "^\s*[MR]\s+\.gitattributes" -and
    $_ -notmatch "^\s*[MR]\s+\.gitignore"
}
if ($bad) {
    $bad | ForEach-Object { Write-Log "ABORT: Modified app file: $_" }
    Write-Log "OpenClaw must push or discard changes first."
    exit 0
}
Write-Log "Working tree clean"

# git pull
$p = Run-Cmd "git pull --ff-only origin main"
if ($null -eq $p) { Write-Log "ABORT: git pull failed"; exit 0 }
Write-Log "git pull: OK"

# Read handoff
$hc = Read-Text (Join-Path $RepoPath ".agent\handoff_to_hermes.md")
if (-not $hc) { Write-Log "ERROR: handoff not found"; exit 1 }
if ($hc -notmatch "Status:\s*WAITING_FOR_HERMES") { Write-Log "No waiting handoff. Stop."; exit 0 }
Write-Log "Handoff is WAITING_FOR_HERMES -- starting validation"

$ch = "unknown"
if ($hc -match "Commit:\s*[`']([0-9a-f]+)[`']") { $ch = $matches[1] }
Write-Log "Target commit: $ch"

# flutter analyze
$ao = Join-Path $logsDir "flutter_analyze_auto.txt"
$result = Run-Flutter "analyze" $ao
$ac = $result.Output
$en = 0; if ($ac -match "(\d+) errors? found") { $en = [int]$matches[1] }
$in = 0; if ($ac -match "(\d+) issues? found") { $in = [int]$matches[1] }
$ar = "0 errors ($in issues)"
Write-Log "flutter analyze: PASS ($ar, $($result.Seconds)s)"

# flutter test
$to = Join-Path $logsDir "flutter_test_auto.txt"
$result = Run-Flutter "test" $to
$tc = $result.Output
$tp = if ($tc -match "All tests passed!") { "All passed" } elseif ($tc -match "(\d+) tests? passed!") { "$($matches[1]) passed" } else { "N/A" }
Write-Log "flutter test: PASS ($tp, $($result.Seconds)s)"

# flutter build
$bo = Join-Path $logsDir "flutter_build_auto.txt"
$result = Run-Flutter "build apk --release" $bo
$bc = $result.Output
$bn = "N/A"; $bp = "N/A"
if ($bc -match "Built .+\\app\\outputs\\flutter-apk\\(.+\.apk)") { $bn = $Matches[1]; $bp = "build\app\outputs\flutter-apk\$bn" }
elseif ($bc -match "Built (.+\.apk)") { $m = [regex]::Match($bc,"Built (.+\.apk)"); $bn = [IO.Path]::GetFileName($m.Groups[1].Value); $bp = "build\app\outputs\flutter-apk\$bn" }
Write-Log "flutter build: PASS ($bn, $($result.Seconds)s)"

# All PASS - update via Python
Write-Log "All checks passed -- updating .agent files..."
$py = Join-Path $RepoPath "scripts\_auto_review_update.py"
$res = & python $py $RepoPath $ts $ch $ar $tp $bn $bp 2>&1
Write-Log "Python: $res"

# git add + commit + push
$p = Run-Cmd "git add .agent\hermes_review.md .agent\handoff_to_hermes.md"
if ($null -eq $p) { Write-Log "ERROR: git add failed"; exit 1 }
$p = Run-Cmd "git commit -m `"docs: auto mark hermes validation pass`""
if ($null -eq $p) { Write-Log "ERROR: git commit failed"; exit 1 }
$p = Run-Cmd "git push"
if ($null -eq $p) { Write-Log "ERROR: git push failed"; exit 1 }
Write-Log "git push: success"
Write-Log "Hermes Windows Auto Review END (PASS)"
Write-Log "========================================"
exit 0
