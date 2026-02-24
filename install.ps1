# claude-code-security-skill installer for Windows with security check
# Enhanced version with automatic security verification
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$SKILL_DIR = "$env:USERPROFILE\.claude\skills\code-security"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SKILL_FILE = Join-Path $SCRIPT_DIR "SKILL.md"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Claude Code Security Skill"
Write-Host "  Enhanced Installer v2.0"
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# ⚠️ NEW: Security Check Step 0
Write-Host "[0/5] Security Check..." -ForegroundColor Yellow

if (-not (Test-Path $SKILL_FILE)) {
    Write-Host "  FAIL SKILL.md not found in $SCRIPT_DIR" -ForegroundColor Red
    exit 1
}

# Check 1: File size sanity check (should be 5-50 KB)
$fileSize = (Get-Item $SKILL_FILE).Length
if ($fileSize -lt 5000 -or $fileSize -gt 50000) {
    Write-Host "  WARNING Unusual file size: $fileSize bytes" -ForegroundColor Red
    Write-Host "  Expected: 5-50 KB" -ForegroundColor Yellow
    $confirm = Read-Host "  Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "  Aborted" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  OK File size: $fileSize bytes" -ForegroundColor Green
}

# Check 2: Dangerous pattern detection
$dangerousPatterns = @(
    "eval\(",
    "exec\(",
    "system\(",
    "__import__",
    "subprocess\.call",
    "os\.system",
    "rm -rf",
    "mkfs",
    "curl.*\|.*sh",
    "wget.*\|.*sh",
    "curl.*bash",
    "wget.*bash",
    "Invoke-Expression",
    "iex "
)

Write-Host "  Scanning for dangerous patterns..." -ForegroundColor Blue
$content = Get-Content $SKILL_FILE -Raw
$safe = $true

foreach ($pattern in $dangerousPatterns) {
    if ($content -match $pattern) {
        Write-Host "  WARNING Found suspicious pattern: $pattern" -ForegroundColor Red
        $safe = $false
    }
}

if (-not $safe) {
    Write-Host "  SECURITY ALERT Dangerous patterns detected!" -ForegroundColor Red
    Write-Host "  This SKILL.md may be malicious" -ForegroundColor Yellow
    $confirm = Read-Host "  Continue anyway? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "  Aborted" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  OK No dangerous patterns found" -ForegroundColor Green
}

# Check 3: YAML frontmatter validation
Write-Host "  Validating SKILL.md structure..." -ForegroundColor Blue
if ($content -notmatch "^name:") {
    Write-Host "  WARNING Missing 'name' field in frontmatter" -ForegroundColor Red
} else {
    Write-Host "  OK Frontmatter structure valid" -ForegroundColor Green
}

# Check 4: SHA256 checksum (if .sha256 file exists)
$sha256File = Join-Path $SCRIPT_DIR "SKILL.md.sha256"
if (Test-Path $sha256File) {
    Write-Host "  Verifying SHA256 checksum..." -ForegroundColor Blue
    try {
        $expectedHash = Get-Content $sha256File -Raw
        $fileHash = (Get-FileHash -Path $SKILL_FILE -Algorithm SHA256).Hash.ToLower()

        if ($expectedHash -match $fileHash) {
            Write-Host "  OK SHA256 checksum verified" -ForegroundColor Green
        } else {
            Write-Host "  FAIL SHA256 checksum mismatch!" -ForegroundColor Red
            Write-Host "  Expected: $expectedHash" -ForegroundColor Red
            Write-Host "  Got: $fileHash" -ForegroundColor Red
            $confirm = Read-Host "  Continue anyway? (y/N)"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                Write-Host "  Aborted" -ForegroundColor Red
                exit 1
            }
        }
    } catch {
        Write-Host "  WARNING SHA256 verification failed: $_" -ForegroundColor Yellow
    }
}

Write-Host "  ✓ Security check passed" -ForegroundColor Green
Write-Host ""

# Step 1: Check Python
Write-Host "[1/4] Checking Python..." -ForegroundColor Yellow
$pyCmd = $null
try {
    $pyVer = & python --version 2>&1
    if ($pyVer -match "Python") {
        $pyCmd = "python"
        Write-Host "  OK $pyVer" -ForegroundColor Green
    }
} catch {}

if (-not $pyCmd) {
    try {
        $pyVer = & python3 --version 2>&1
        if ($pyVer -match "Python") {
            $pyCmd = "python3"
            Write-Host "  OK $pyVer" -ForegroundColor Green
        }
    } catch {}
}

if (-not $pyCmd) {
    Write-Host "  FAIL Python not found" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install Python 3.8+ first:"
    Write-Host "  https://www.python.org/downloads/"
    exit 1
}

# Step 2: Check/Install Semgrep
Write-Host "[2/4] Checking Semgrep..." -ForegroundColor Yellow
$sgInstalled = $false
try {
    $sgVer = & semgrep --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sgInstalled = $true
        Write-Host "  OK Semgrep $sgVer" -ForegroundColor Green
    }
} catch {}

if (-not $sgInstalled) {
    Write-Host "  NOT FOUND Installing Semgrep..." -ForegroundColor Yellow
    & $pyCmd -m pip install semgrep --quiet
    try {
        $sgVer = & semgrep --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK Semgrep $sgVer installed" -ForegroundColor Green
        } else {
            throw "Install failed"
        }
    } catch {
        Write-Host "  FAIL Semgrep installation failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Try manually: pip install semgrep"
        Write-Host "  Then add Python Scripts folder to PATH"
        exit 1
    }
}

# Step 3: Install Skill
Write-Host "[3/4] Installing Skill..." -ForegroundColor Yellow
$skillFile = Join-Path $SCRIPT_DIR "SKILL.md"
if (-not (Test-Path $skillFile)) {
    Write-Host "  FAIL SKILL.md not found in $SCRIPT_DIR" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $SKILL_DIR)) {
    New-Item -ItemType Directory -Path $SKILL_DIR -Force | Out-Null
}
Copy-Item $skillFile -Destination (Join-Path $SKILL_DIR "SKILL.md") -Force
Write-Host "  OK Copied to $SKILL_DIR\SKILL.md" -ForegroundColor Green

# Step 4: Verify
Write-Host "[4/4] Verifying..." -ForegroundColor Yellow
if (Test-Path (Join-Path $SKILL_DIR "SKILL.md")) {
    Write-Host "  OK Skill file exists" -ForegroundColor Green
} else {
    Write-Host "  FAIL Skill file not found after copy" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Skill location: $SKILL_DIR\SKILL.md"
Write-Host "  Hot Reloading: No restart needed"
Write-Host ""
Write-Host "  Usage in Claude Code:"
Write-Host "    - Say: 安全扫描一下这个项目"
Write-Host "    - Say: 扫一下有没有漏洞"
Write-Host "    - Or:  /code-security"
Write-Host ""
