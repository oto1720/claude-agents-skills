#!/usr/bin/env bash
# validate-agents.sh
# Flutter エージェントの構造を検証する

set -euo pipefail

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

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"

echo "========================================"
echo " Flutter Agent Validator"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# 必須 Flutter エージェントのチェック
REQUIRED_AGENTS=(
  "flutter-architect.md"
  "flutter-reviewer.md"
  "flutter-build-resolver.md"
  "flutter-test-runner.md"
  "flutter-performance-analyzer.md"
)

echo "### 必須エージェントの存在確認"
for agent in "${REQUIRED_AGENTS[@]}"; do
  if [ -f "$AGENTS_DIR/$agent" ]; then
    pass "$agent が存在する"
  else
    fail "$agent が存在しない"
  fi
done

echo ""
echo "### エージェントファイルの構造検証"

for agent_file in "$AGENTS_DIR"/flutter-*.md; do
  agent_name=$(basename "$agent_file")
  echo ""
  echo "--- $agent_name ---"

  # frontmatter の存在チェック
  if head -1 "$agent_file" | grep -q "^---$"; then
    pass "frontmatter が存在する"
  else
    fail "frontmatter がない（--- で始まる YAML が必要）"
  fi

  # name フィールドのチェック
  if grep -q "^name:" "$agent_file"; then
    NAME=$(grep "^name:" "$agent_file" | head -1 | sed 's/name: //')
    pass "name フィールド: $NAME"
  else
    fail "name フィールドがない"
  fi

  # description フィールドのチェック
  if grep -q "^description:" "$agent_file"; then
    pass "description フィールドがある"
  else
    fail "description フィールドがない"
  fi

  # model フィールドのチェック
  if grep -q "^model:" "$agent_file"; then
    MODEL=$(grep "^model:" "$agent_file" | head -1 | sed 's/model: //')
    pass "model フィールド: $MODEL"
  else
    warn "model フィールドがない（デフォルトが使われる）"
  fi

  # allowed-tools フィールドのチェック
  if grep -q "^allowed-tools:" "$agent_file"; then
    pass "allowed-tools フィールドがある"
  else
    warn "allowed-tools フィールドがない"
  fi

  # Step セクションのチェック（エージェントが手順を持つか）
  STEP_COUNT=$(grep -c "^## Step" "$agent_file" || true)
  if [ "$STEP_COUNT" -ge 2 ]; then
    pass "Step セクション: ${STEP_COUNT}個"
  else
    warn "Step セクションが少ない（${STEP_COUNT}個）。2個以上推奨"
  fi

  # 品質基準セクションのチェック
  if grep -q "品質基準" "$agent_file"; then
    pass "品質基準セクションがある"
  else
    warn "品質基準セクションがない"
  fi

  # 行数チェック
  LINES=$(wc -l < "$agent_file")
  if [ "$LINES" -ge 50 ]; then
    pass "行数: ${LINES}行（十分な詳細度）"
  else
    warn "行数: ${LINES}行（50行以上推奨）"
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
  echo ""
  echo -e "${RED}❌ 検証失敗: ${FAIL}個の問題を修正してください${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ 全エージェントの検証完了${NC}"
fi
