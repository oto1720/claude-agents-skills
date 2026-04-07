#!/usr/bin/env bash
# validate-rules.sh
# rules/ ディレクトリの構造を検証する

PASS=0
FAIL=0
WARN=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}❌ FAIL${NC}: $1"; FAIL=$((FAIL+1)); }
warn() { echo -e "${YELLOW}⚠️  WARN${NC}: $1"; WARN=$((WARN+1)); }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULES_DIR="$ROOT/rules"

echo "========================================"
echo " Flutter Rules Validator"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# 必須ディレクトリのチェック
echo "### 必須ディレクトリの確認"
for dir in common dart flutter; do
  if [ -d "$RULES_DIR/$dir" ]; then
    FILE_COUNT=$(find "$RULES_DIR/$dir" -name "*.md" | wc -l | tr -d ' ')
    pass "rules/$dir/ が存在する（${FILE_COUNT}個のファイル）"
  else
    fail "rules/$dir/ が存在しない"
  fi
done

# 必須ルールファイルのチェック
echo ""
echo "### 必須ルールファイルの確認"

check_file() {
  local f="$1"
  if [ -f "$RULES_DIR/$f" ]; then
    LINES=$(wc -l < "$RULES_DIR/$f" | tr -d ' ')
    pass "rules/$f (${LINES} lines)"
  else
    fail "rules/$f が存在しない"
  fi
}

check_file "common/coding-style.md"
check_file "common/testing.md"
check_file "common/security.md"
check_file "common/git-workflow.md"
check_file "common/performance.md"
check_file "common/agents.md"
check_file "common/code-review.md"
check_file "dart/style.md"
check_file "dart/async.md"
check_file "flutter/widgets.md"
check_file "flutter/state-management.md"
check_file "flutter/testing.md"

# ルールファイルの品質チェック
echo ""
echo "### ルールファイルの品質チェック"

find "$RULES_DIR" -name "*.md" | sort | while read -r md_file; do
  rel_path="${md_file#$ROOT/}"
  LINES=$(wc -l < "$md_file" | tr -d ' ')

  if [ "$LINES" -lt 10 ]; then
    echo -e "${YELLOW}⚠️  WARN${NC}: $rel_path: 内容が少ない（${LINES}行）"
  fi

  if grep -q "^\`\`\`" "$md_file"; then
    echo -e "${GREEN}✅ PASS${NC}: $rel_path: コード例がある"
  else
    echo -e "${YELLOW}⚠️  WARN${NC}: $rel_path: コード例がない"
  fi
done

echo ""
echo "========================================"
echo " 結果サマリー"
echo "========================================"
echo -e "  ${GREEN}PASS${NC}: $PASS"
echo -e "  ${YELLOW}WARN${NC}: $WARN"
echo -e "  ${RED}FAIL${NC}: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo -e "${RED}❌ 検証失敗${NC}"
  exit 1
else
  echo -e "${GREEN}✅ rules/ の検証完了${NC}"
fi
