#!/usr/bin/env bash
# validate-hooks.sh
# hooks.json の構造を検証する

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

HOOKS_FILE="$(cd "$(dirname "$0")/.." && pwd)/hooks/hooks.json"

echo "========================================"
echo " Flutter Hooks Validator"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# ファイル存在チェック
if [ -f "$HOOKS_FILE" ]; then
  pass "hooks.json が存在する"
else
  fail "hooks.json が存在しない: $HOOKS_FILE"
  exit 1
fi

# JSON 構文チェック
echo ""
echo "### JSON 構文検証"
if python3 -m json.tool "$HOOKS_FILE" > /dev/null 2>&1; then
  pass "JSON 構文が正しい"
else
  fail "JSON 構文エラー: $(python3 -m json.tool "$HOOKS_FILE" 2>&1)"
  exit 1
fi

# 必須ライフサイクルのチェック
echo ""
echo "### ライフサイクルフックの確認"

LIFECYCLES=("PreToolUse" "PostToolUse" "PreCompact" "Stop" "SessionStart")
for lifecycle in "${LIFECYCLES[@]}"; do
  if python3 -c "
import json, sys
with open('$HOOKS_FILE') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
if '$lifecycle' in hooks and len(hooks['$lifecycle']) > 0:
    print('FOUND')
else:
    print('MISSING')
" 2>/dev/null | grep -q "FOUND"; then
    COUNT=$(python3 -c "
import json
with open('$HOOKS_FILE') as f:
    data = json.load(f)
print(len(data.get('hooks', {}).get('$lifecycle', [])))
")
    pass "$lifecycle: ${COUNT}個のフック"
  else
    warn "$lifecycle フックがない"
  fi
done

# Flutter 固有フックのチェック
echo ""
echo "### Flutter 固有フックの確認"

REQUIRED_HOOK_IDS=(
  "post:edit:dart-format"
  "post:edit:flutter-analyze"
  "pre:bash:pubspec-check"
  "pre:bash:block-no-verify"
  "stop:flutter-quality"
)

ALL_IDS=$(python3 -c "
import json
with open('$HOOKS_FILE') as f:
    data = json.load(f)
ids = []
for lifecycle, hooks_list in data.get('hooks', {}).items():
    for hook in hooks_list:
        if 'id' in hook:
            ids.append(hook['id'])
print('\n'.join(ids))
")

for hook_id in "${REQUIRED_HOOK_IDS[@]}"; do
  if echo "$ALL_IDS" | grep -q "^${hook_id}$"; then
    pass "hook id: $hook_id"
  else
    fail "hook id が見つからない: $hook_id"
  fi
done

# フック構造の検証
echo ""
echo "### フック構造の詳細検証"

python3 << EOF
import json, sys

with open('$HOOKS_FILE') as f:
    data = json.load(f)

issues = []
passes = []

for lifecycle, hooks_list in data.get('hooks', {}).items():
    for hook_entry in hooks_list:
        hook_id = hook_entry.get('id', 'unknown')

        # 必須フィールドのチェック
        if 'hooks' not in hook_entry:
            issues.append(f"{hook_id}: 'hooks' フィールドがない")
        elif not hook_entry['hooks']:
            issues.append(f"{hook_id}: 'hooks' が空")
        else:
            for h in hook_entry['hooks']:
                if 'type' not in h:
                    issues.append(f"{hook_id}: 'type' フィールドがない")
                if 'command' not in h:
                    issues.append(f"{hook_id}: 'command' フィールドがない")
                elif len(h['command']) < 10:
                    issues.append(f"{hook_id}: command が短すぎる")
                else:
                    passes.append(f"{hook_id}: 構造が正しい")

        # description のチェック
        if 'description' not in hook_entry:
            issues.append(f"{hook_id}: 'description' がない（推奨）")

for p in passes:
    print(f"\033[0;32m✅ PASS\033[0m: {p}")
for i in issues:
    print(f"\033[0;31m❌ FAIL\033[0m: {i}")
EOF

echo ""
echo "========================================"
echo " 結果サマリー"
echo "========================================"
echo -e "  ${GREEN}PASS${NC}: $PASS"
echo -e "  ${YELLOW}WARN${NC}: $WARN"
echo -e "  ${RED}FAIL${NC}: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo -e "${RED}❌ 検証失敗${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}✅ hooks.json の検証完了${NC}"
fi
