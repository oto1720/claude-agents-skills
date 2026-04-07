#!/usr/bin/env bash
# validate-skills.sh
# Flutter スキルの構造を検証する

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

SKILLS_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills"

echo "========================================"
echo " Flutter Skill Validator"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# 必須 Flutter スキルのチェック
REQUIRED_SKILLS=(
  "flutter-widget-design"
  "flutter-state-management"
  "flutter-testing"
  "flutter-architecture"
  "flutter-performance"
  "flutter-ci-cd"
)

echo "### 必須スキルの存在確認"
for skill in "${REQUIRED_SKILLS[@]}"; do
  if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
    pass "$skill/SKILL.md が存在する"
  else
    fail "$skill/SKILL.md が存在しない"
  fi
done

echo ""
echo "### スキルファイルの構造検証"

for skill_file in "$SKILLS_DIR"/flutter-*/SKILL.md; do
  skill_name=$(dirname "$skill_file" | xargs basename)
  echo ""
  echo "--- $skill_name ---"

  # frontmatter の存在チェック
  if head -1 "$skill_file" | grep -q "^---$"; then
    pass "frontmatter が存在する"
  else
    fail "frontmatter がない"
  fi

  # name フィールドのチェック
  if grep -q "^name:" "$skill_file"; then
    NAME=$(grep "^name:" "$skill_file" | head -1 | sed 's/name: //')
    pass "name: $NAME"
  else
    fail "name フィールドがない"
  fi

  # description フィールドのチェック
  if grep -q "^description:" "$skill_file"; then
    pass "description フィールドがある"
  else
    fail "description フィールドがない"
  fi

  # 「いつ使うか」セクション
  if grep -q "いつ使うか" "$skill_file"; then
    pass "「いつ使うか」セクションがある"
  else
    warn "「いつ使うか」セクションがない（使用タイミングの明示推奨）"
  fi

  # コード例のチェック
  CODE_BLOCKS=$(grep -c "^\`\`\`dart" "$skill_file" || true)
  if [ "$CODE_BLOCKS" -ge 2 ]; then
    pass "Dart コード例: ${CODE_BLOCKS}個"
  else
    warn "Dart コード例が少ない（${CODE_BLOCKS}個）。2個以上推奨"
  fi

  # チェックリストのチェック
  if grep -q "^- \[" "$skill_file"; then
    CHECKLIST_COUNT=$(grep -c "^- \[" "$skill_file" || true)
    pass "チェックリスト: ${CHECKLIST_COUNT}項目"
  else
    warn "チェックリストがない（確認事項の一覧推奨）"
  fi

  # アンチパターンのチェック
  if grep -qi "アンチパターン\|❌\|禁止" "$skill_file"; then
    pass "アンチパターン/禁止事項が記載されている"
  else
    warn "アンチパターンの記載がない"
  fi

  # 行数チェック
  LINES=$(wc -l < "$skill_file")
  if [ "$LINES" -ge 40 ]; then
    pass "行数: ${LINES}行（十分な詳細度）"
  else
    warn "行数: ${LINES}行（40行以上推奨）"
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
  echo -e "${GREEN}✅ 全スキルの検証完了${NC}"
fi
