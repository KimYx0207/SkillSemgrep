#!/usr/bin/env bash
# claude-code-security-skill installer with security check
# Enhanced version with automatic security verification

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SKILL_DIR="$HOME/.claude/skills/code-security"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/SKILL.md"

echo ""
echo "=================================="
echo "  Claude Code Security Skill"
echo "  Enhanced Installer v2.0"
echo "=================================="
echo ""

# ⚠️ NEW: Security Check Step 0
echo -e "${YELLOW}[0/5]${NC} ${BLUE}Security Check${NC}..."
if [ ! -f "$SKILL_FILE" ]; then
    echo -e "  ${RED}FAIL${NC} SKILL.md not found in $SCRIPT_DIR"
    exit 1
fi

# Check 1: File size sanity check (should be 5-50 KB)
FILE_SIZE=$(stat -f%z "$SKILL_FILE" 2>/dev/null || stat -c%s "$SKILL_FILE" 2>/dev/null)
if [ "$FILE_SIZE" -lt 5000 ] || [ "$FILE_SIZE" -gt 50000 ]; then
    echo -e "  ${RED}WARNING${NC} Unusual file size: $FILE_SIZE bytes"
    echo -e "  ${YELLOW}Expected: 5-50 KB${NC}"
    read -p "  Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "  ${RED}Aborted${NC}"
        exit 1
    fi
else
    echo -e "  ${GREEN}OK${NC} File size: $FILE_SIZE bytes"
fi

# Check 2: Dangerous pattern detection
DANGEROUS_PATTERNS=(
    "eval\("
    "exec\("
    "system\("
    "__import__"
    "subprocess\.call"
    "os\.system"
    "rm -rf"
    "mkfs"
    ":(){ :\|:& };:"
    "curl.*\|.*sh"
    "wget.*\|.*sh"
    "curl.*bash"
    "wget.*bash"
)

echo -e "  ${BLUE}Scanning for dangerous patterns...${NC}"
SAFE=true
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if grep -qE "$pattern" "$SKILL_FILE"; then
        echo -e "  ${RED}WARNING${NC} Found suspicious pattern: $pattern"
        SAFE=false
    fi
done

if [ "$SAFE" = false ]; then
    echo -e "  ${RED}SECURITY ALERT${NC} Dangerous patterns detected!"
    echo -e "  ${YELLOW}This SKILL.md may be malicious${NC}"
    read -p "  Continue anyway? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "  ${RED}Aborted${NC}"
        exit 1
    fi
else
    echo -e "  ${GREEN}OK${NC} No dangerous patterns found"
fi

# Check 3: YAML frontmatter validation
echo -e "  ${BLUE}Validating SKILL.md structure...${NC}"
if ! grep -q "^name:" "$SKILL_FILE"; then
    echo -e "  ${RED}WARNING${NC} Missing 'name' field in frontmatter"
else
    echo -e "  ${GREEN}OK${NC} Frontmatter structure valid"
fi

# Check 4: SHA256 checksum (if .sha256 file exists)
SHA256_FILE="$SCRIPT_DIR/SKILL.md.sha256"
if [ -f "$SHA256_FILE" ]; then
    echo -e "  ${BLUE}Verifying SHA256 checksum...${NC}"
    if command -v sha256sum &>/dev/null; then
        if sha256sum -c "$SHA256_FILE" &>/dev/null; then
            echo -e "  ${GREEN}OK${NC} SHA256 checksum verified"
        else
            echo -e "  ${RED}FAIL${NC} SHA256 checksum mismatch!"
            read -p "  Continue anyway? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo -e "  ${RED}Aborted${NC}"
                exit 1
            fi
        fi
    elif command -v shasum &>/dev/null; then
        # macOS fallback
        if shasum -a 256 -c "$SHA256_FILE" &>/dev/null; then
            echo -e "  ${GREEN}OK${NC} SHA256 checksum verified"
        else
            echo -e "  ${RED}FAIL${NC} SHA256 checksum mismatch!"
            read -p "  Continue anyway? (y/N): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                echo -e "  ${RED}Aborted${NC}"
                exit 1
            fi
        fi
    else
        echo -e "  ${YELLOW}SKIP${NC} sha256sum not found, cannot verify"
    fi
fi

echo -e "  ${GREEN}✓ Security check passed${NC}"
echo ""

# Step 1: Check Python
echo -e "${YELLOW}[1/4]${NC} Checking Python..."
if command -v python3 &>/dev/null; then
    PY_CMD="python3"
    PY_VER=$($PY_CMD --version 2>&1)
    echo -e "  ${GREEN}OK${NC} $PY_VER"
elif command -v python &>/dev/null; then
    PY_CMD="python"
    PY_VER=$($PY_CMD --version 2>&1)
    echo -e "  ${GREEN}OK${NC} $PY_VER"
else
    echo -e "  ${RED}FAIL${NC} Python not found"
    echo ""
    echo "  Please install Python 3.8+ first:"
    echo "  https://www.python.org/downloads/"
    exit 1
fi

# Step 2: Check/Install Semgrep
echo -e "${YELLOW}[2/4]${NC} Checking Semgrep..."
if command -v semgrep &>/dev/null; then
    SG_VER=$(semgrep --version 2>&1)
    echo -e "  ${GREEN}OK${NC} Semgrep $SG_VER"
else
    echo -e "  ${YELLOW}NOT FOUND${NC} Installing Semgrep..."
    $PY_CMD -m pip install semgrep --quiet
    if command -v semgrep &>/dev/null; then
        SG_VER=$(semgrep --version 2>&1)
        echo -e "  ${GREEN}OK${NC} Semgrep $SG_VER installed"
    else
        echo -e "  ${RED}FAIL${NC} Semgrep installation failed"
        echo ""
        echo "  Try manually: pip install semgrep"
        echo "  If 'command not found', add Python Scripts to PATH"
        exit 1
    fi
fi

# Step 3: Install Skill
echo -e "${YELLOW}[3/4]${NC} Installing Skill..."
if [ ! -f "$SCRIPT_DIR/SKILL.md" ]; then
    echo -e "  ${RED}FAIL${NC} SKILL.md not found in $SCRIPT_DIR"
    exit 1
fi

mkdir -p "$SKILL_DIR"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
echo -e "  ${GREEN}OK${NC} Copied to $SKILL_DIR/SKILL.md"

# Step 4: Verify
echo -e "${YELLOW}[4/4]${NC} Verifying..."
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo -e "  ${GREEN}OK${NC} Skill file exists"
else
    echo -e "  ${RED}FAIL${NC} Skill file not found after copy"
    exit 1
fi

echo ""
echo "=================================="
echo -e "  ${GREEN}Installation Complete!${NC}"
echo "=================================="
echo ""
echo "  Skill location: $SKILL_DIR/SKILL.md"
echo "  Hot Reloading: No restart needed"
echo ""
echo "  Usage in Claude Code:"
echo "    - Say: 安全扫描一下这个项目"
echo "    - Say: 扫一下有没有漏洞"
echo "    - Or:  /code-security"
echo ""
