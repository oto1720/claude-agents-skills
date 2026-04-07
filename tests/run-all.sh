#!/usr/bin/env bash
# run-all.sh
# Flutter ハーネスの全バリデーションを実行する

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo "╔════════════════════════════════════════╗"
echo "║   Flutter Harness — Full Validation    ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')            ║"
echo "╚════════════════════════════════════════╝"
echo ""

run_test() {
  local script="$1"
  local name="$2"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}▶ $name${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if bash "$TESTS_DIR/$script" 2>&1; then
    echo ""
    echo -e "${GREEN}▶ $name — PASSED${NC}"
    ((PASS_COUNT++))
  else
    echo ""
    echo -e "${RED}▶ $name — FAILED${NC}"
    ((FAIL_COUNT++))
  fi
}

# 実行権限を付与
chmod +x "$TESTS_DIR"/*.sh

# 各バリデーションを実行
run_test "validate-agents.sh"  "Agent Validation"
run_test "validate-skills.sh"  "Skill Validation"
run_test "validate-hooks.sh"   "Hooks Validation"
run_test "validate-rules.sh"   "Rules Validation"

# 最終サマリー
echo ""
echo "╔════════════════════════════════════════╗"
echo "║          FINAL RESULTS                 ║"
echo "╠════════════════════════════════════════╣"
echo -e "║  ${GREEN}PASSED${NC}: $PASS_COUNT / $((PASS_COUNT + FAIL_COUNT)) suites                    ║"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo -e "║  ${RED}FAILED${NC}: $FAIL_COUNT suite(s)                      ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo -e "${RED}❌ 一部のバリデーションが失敗しました。上記のエラーを修正してください。${NC}"
  exit 1
else
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo -e "${GREEN}✅ 全バリデーション通過！Flutter ハーネスの品質が確認されました。${NC}"
fi
