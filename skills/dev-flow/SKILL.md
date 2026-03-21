---
name: dev-flow
description: |
  GitHubのissueナンバーを指定するだけで、ドキュメント参照→実装→コミット→プッシュ→PR作成→PRレビューまでを一貫して行う開発フロースキル。
  以下のトリガーで自動発動:
  - 「issue #N を実装して」「issue #N やって」「#N の実装を進めて」
  - 「issueを実装してコミットまでして」「開発フローを回して」
  - /dev-flow [issue番号]
  - ユーザーがissue番号を指定して実装・PR作成を依頼したとき必ず使うこと
allowed-tools: Read, Glob, Grep, Bash, Write, Agent, mcp__githubApi__get_issue, mcp__githubApi__create_pull_request, mcp__githubApi__create_pull_request_review, mcp__githubApi__get_pull_request_files
---

# Dev Flow Skill

GitHubのissueを起点に、**計画 → 実装 → コミット/プッシュ/PR → レビュー** までを自動で行う開発フロースキル。

## 入力

`$ARGUMENTS` にissueナンバー（例: `42` または `#42`）を受け取る。

例:
- `/dev-flow 42` — issue #42 を実装してPRまで出す
- `/dev-flow #15` — issue #15 を実装してPRまで出す

## 実行フロー

### Step 1: Issue の取得とプロジェクトコンテキストの収集

```bash
# issueナンバーを正規化（#を除去）
ISSUE_NUM=$(echo "$ARGUMENTS" | tr -d '#')

# GitHubリポジトリ情報の取得
gh repo view --json name,owner,defaultBranchRef

# Issueの内容を取得
gh issue view $ISSUE_NUM --json title,body,labels,assignees,comments
```

プロジェクトドキュメントを収集する:

```bash
# プロジェクト設計ドキュメントの探索
find . -maxdepth 3 -name "*.md" \( \
  -path "*/docs/*" -o \
  -path "*/documents/*" -o \
  -path "*/doc/*" -o \
  -name "README*" -o \
  -name "CLAUDE*" -o \
  -name "ARCHITECTURE*" -o \
  -name "DESIGN*" \
\) | head -30

# CLAUDE.md（プロジェクト規約）を優先的に読む
cat CLAUDE.md 2>/dev/null || cat .claude/CLAUDE.md 2>/dev/null
```

### Step 2: issue-planner エージェントで実装計画を立てる

`agents/issue-planner.md` のエージェントを呼び出す:

```
Issue内容:
{issue title}
{issue body}

プロジェクトのドキュメントパス一覧:
{見つかったdocsのパス}

リポジトリ情報:
{owner/repo, default branch}
```

エージェントは以下を返す:
- **ブランチ名**: `feature/issue-{N}-{短い説明}`
- **実装計画**: 変更すべきファイルと変更内容の一覧
- **受け入れ条件**: issueのAcceptance Criteriaまたは推測された完了条件

### Step 3: 作業ブランチの作成

```bash
# mainブランチの最新を取得
MAIN_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

# 作業ブランチを作成
BRANCH_NAME="feature/issue-${ISSUE_NUM}-{planner が提案した短い説明}"
git checkout -b $BRANCH_NAME
```

### Step 4: implementer エージェントで実装

`agents/implementer.md` のエージェントを呼び出す:

```
Issue #N: {title}
ブランチ: {branch_name}

実装計画:
{issue-planner の出力}

プロジェクト規約:
{CLAUDE.md の内容}
```

エージェントは実際にファイルを作成・変更して実装を行う。

### Step 5: コミットとプッシュ

```bash
# 変更のステータス確認
git status
git diff --stat

# 変更をステージング（.env等は除外）
git add --all
git reset HEAD .env .env.local .env.*.local 2>/dev/null || true

# コミット（issue番号を含む）
git commit -m "$(cat <<'EOF'
feat: issue #{N} {issue title の要約}

{変更内容の1-2行説明}

Closes #{N}

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"

# プッシュ
git push origin $BRANCH_NAME
```

### Step 6: PR の作成

```bash
gh pr create \
  --title "feat: issue #{N} {issue title}" \
  --body "$(cat <<'EOF'
## 概要

Closes #{N}

{issue の概要を1-3文で}

## 変更内容

{変更したファイルと変更内容の箇条書き}

## 動作確認

{受け入れ条件に対するチェックリスト}
- [ ] {条件1}
- [ ] {条件2}

## 関連

- issue #{N}: {issue URL}

🤖 Generated with [Claude Code](https://claude.com/claude-code) / dev-flow skill
EOF
)" \
  --base $MAIN_BRANCH
```

### Step 7: PR レビュー

`pr-review` skill を使って作成したPRをレビューする:

```
/pr-review {branch_name}
```

または直接 git diff を使ってレビューを実施し、`docs/reviews/pr_review_{branch}_{YYYYMMDD}.md` に出力する。

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| issueが見つからない | `gh issue view` のエラーを確認してユーザーに報告 |
| コンフリクト発生 | ユーザーに報告し、解決を依頼 |
| テスト失敗 | 失敗内容を表示してコミット前に修正を試みる |
| PRが既に存在する | 既存PRのURLを表示して継続確認 |

## 完了メッセージ

```
✅ Dev Flow 完了

📌 Issue:    #{N} {title}
🌿 Branch:   {branch_name}
🔗 PR:       {PR URL}

📄 PRレビュー: docs/reviews/pr_review_{branch}_{date}.md
🎯 マージ判定: [APPROVE / REQUEST CHANGES]
```

## 注意事項

- **コミット前に `git status` を必ず確認**し、意図しないファイルを含めない
- `.env` や認証情報を含むファイルは絶対にコミットしない
- issueのラベルやマイルストーンを参考にブランチ名・コミットメッセージの粒度を決める
- プロジェクトに `CLAUDE.md` がある場合はその規約を最優先する
