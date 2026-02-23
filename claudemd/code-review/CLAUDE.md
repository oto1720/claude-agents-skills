# CLAUDE.md — コードレビュー自動化設定

このCLAUDE.mdはコードレビュー用のSkillとAgentを設定します。

## 利用可能なSkill

| Skill | コマンド | 用途 |
|-------|---------|------|
| `code-review` | `/code-review [パス]` | ファイル・ディレクトリの総合コードレビュー |
| `pr-review` | `/pr-review [ブランチ名]` | PRの差分レビュー・マージ判定 |
| `security-review` | `/security-review [パス]` | セキュリティ脆弱性スキャン |

## 利用可能なAgent

| Agent | 用途 |
|-------|------|
| `review-analyzer` | 品質・設計・パフォーマンス分析（skill内部で使用） |
| `security-scanner` | セキュリティ脆弱性スキャン（security-review内部で使用） |

---

## 使い方

### パターン1: ファイル・ディレクトリのレビュー

```
/code-review lib/features/auth/
/code-review lib/main.dart
```

→ `docs/reviews/review_{timestamp}.md` に詳細レポートが生成される

### パターン2: PRをマージ前にレビュー

```
/pr-review feature/user-authentication
/pr-review              ← 現在の変更（コミット前）
```

→ `docs/reviews/pr_review_{branch}_{date}.md` にマージ判定付きレポートが生成される

### パターン3: セキュリティチェック

```
/security-review lib/
/security-review        ← プロジェクト全体
```

→ `docs/reviews/security_review_{date}.md` に脆弱性レポートが生成される

---

## 推奨ワークフロー

```
コード実装
    ↓
/code-review [実装したファイル]    ← 自己レビュー
    ↓
指摘事項を修正
    ↓
git add & commit
    ↓
/pr-review [ブランチ名]           ← PRレビュー（マージ前）
    ↓
/security-review                  ← 定期セキュリティチェック（週次など）
```

## 生成されるドキュメント

```
docs/reviews/
├── review_{timestamp}.md          # コードレビューレポート
├── pr_review_{branch}_{date}.md   # PRレビューレポート
└── security_review_{date}.md      # セキュリティレポート
```