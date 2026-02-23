# CLAUDE.md — コード学習自動化設定

このCLAUDE.mdはコードを学習するためのSkillとAgentを設定します。
グローバル設定として `~/.claude/CLAUDE.md` に配置するか、
プロジェクトルートの `CLAUDE.md` に追記してください。

## 利用可能なSkill

| Skill | コマンド | 自動発動タイミング |
|-------|---------|-----------------|
| `code-learner` | `/code-learner` | 「コードを勉強したい」「プロジェクトを理解したい」と言ったとき |
| `feature-learner` | `/feature-learner [機能名]` | 「〇〇機能の学習MDを作って」と言ったとき |

## 利用可能なAgent

| Agent | 用途 |
|-------|------|
| `code-explorer` | コードベースの読み取り専用探索（code-learner内部で使用） |

## 使い方

### パターン1: プロジェクト全体の学習ドキュメントを生成

```
/code-learner
```

または自然言語で:
```
このプロジェクトを勉強したいので学習用のドキュメントを作って
```

→ `docs/learning/` 以下に5つのMDファイルが生成される

### パターン2: 特定機能の学習ドキュメントを生成

```
/feature-learner 認証機能
/feature-learner lib/features/home/
```

または自然言語で:
```
今追加したGPS追跡機能の解説ドキュメントを作って
```

→ `docs/learning/features/{機能名}.md` が生成される

### パターン3: 新機能追加後に自動でドキュメント生成（推奨ワークフロー）

新機能を実装した後、以下を実行:
```
feature-learner skillを使って、今追加した[機能名]の学習MDを docs/learning/features/ に作って
```

## 生成ドキュメントの構成

```
docs/learning/
├── README.md              # インデックス・読む順番
├── 00_overview.md         # プロジェクト全体図・技術スタック
├── 01_architecture.md     # アーキテクチャ解説
├── 02_data_flow.md        # データの流れ
├── 03_key_concepts.md     # 重要な実装パターン
├── 04_getting_started.md  # 開発スタートガイド
└── features/
    ├── auth.md            # 認証機能
    ├── gps_tracking.md    # GPS追跡機能
    └── ...
```