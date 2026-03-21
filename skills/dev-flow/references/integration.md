# Dev Flow — 連携スキル・ツールリファレンス

## 使用するスキル・エージェント

### 内部エージェント（このスキル専用）

| エージェント | パス | 役割 |
|------------|------|------|
| issue-planner | `agents/issue-planner.md` | issueとdocsを読んで実装計画を立てる |
| implementer | `agents/implementer.md` | 実装計画に基づきコードを実装する |

### 連携スキル（既存）

| スキル | パス | 使用タイミング |
|--------|------|--------------|
| pr-review | `skills/pr-review/SKILL.md` | Step 7: PR作成後のレビュー |
| code-review | `skills/code-review/SKILL.md` | 実装後の詳細コードレビューが必要な場合 |

## GitHub MCP ツール

`dev-flow` で使用するMCPツール:

| ツール | 用途 |
|--------|------|
| `mcp__githubApi__get_issue` | issueの詳細取得 |
| `mcp__githubApi__create_pull_request` | PR作成 |
| `mcp__githubApi__create_pull_request_review` | PRレビューコメント投稿 |
| `mcp__githubApi__get_pull_request_files` | PR変更ファイル確認 |

MCPが利用できない場合は `gh` CLI コマンドで代替する。

## プロジェクトドキュメントの探索パターン

プロジェクトによってドキュメントの場所が異なるため、以下の順で探索する:

```
1. CLAUDE.md              ← 最優先（Claude Code用プロジェクト規約）
2. .claude/CLAUDE.md
3. README.md
4. docs/ARCHITECTURE.md
5. docs/DESIGN.md
6. documents/             ← documents ディレクトリ
7. docs/                  ← docs ディレクトリ配下すべて
8. CONTRIBUTING.md
```

## ブランチ命名規則

```
feature/issue-{N}-{kebab-case-description}

例:
- feature/issue-42-add-user-authentication
- feature/issue-15-fix-login-redirect
- feature/issue-100-refactor-payment-service
```

## コミットメッセージ規約

Conventional Commits に従う:

```
{type}: issue #{N} {タイトル要約}

{変更内容の詳細（任意）}

Closes #{N}

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

**type の選び方:**
- `feat` — 新機能の追加
- `fix` — バグ修正
- `refactor` — リファクタリング
- `test` — テスト追加
- `docs` — ドキュメント変更
- `chore` — ビルド・設定変更

プロジェクトに `CLAUDE.md` があり別の規約が指定されている場合は、そちらを優先する。
