---
name: feature-learner
description: |
  新機能を追加したとき、または特定の機能・ファイル群を理解したいときに学習用MDを生成する。
  以下のトリガーで自動発動:
  - 「この機能の学習ドキュメントを作って」
  - 「追加した機能を説明するMDを作りたい」
  - 「〇〇機能の解説ドキュメント」
  - /feature-learner [機能名 or ファイルパス]
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Feature Learner Skill

特定の機能・ファイル群を対象に **機能単位の学習ドキュメント** を生成する。
新機能を追加した直後や、特定モジュールを深く理解したい時に使う。

## 入力

`$ARGUMENTS` に機能名またはファイル/ディレクトリパスを受け取る。

例:
- `/feature-learner 認証機能`
- `/feature-learner lib/features/auth/`
- `/feature-learner GPS追跡機能`

## 実行フロー

### Step 1: 対象ファイルの特定

引数からファイルを特定する:

```bash
# パスが指定された場合
find $ARGUMENTS -type f \( -name "*.dart" -o -name "*.go" -o -name "*.ts" \) 2>/dev/null

# 機能名が指定された場合はgrepで検索
grep -r "$ARGUMENTS" . --include="*.dart" --include="*.go" --include="*.ts" -l \
  | grep -v -E "(build|node_modules|.dart_tool)"
```

### Step 2: 機能の依存関係マッピング

対象ファイルが何に依存し、何から依存されているかを調べる:

```bash
# Dartの場合: importを追う
grep -r "import" $TARGET_FILES | grep -v "flutter\|dart:"

# 関連するモデル・エンティティ
grep -r "class\|typedef\|enum" $TARGET_FILES
```

### Step 3: 機能学習MDの生成

`docs/learning/features/{機能名}.md` を生成:

```markdown
# [機能名] 実装解説

> 生成日時: {date} | 対象ファイル数: N

## 📌 この機能の概要
[何をする機能か、1-2文で説明]

## 📁 ファイル構成
[対象ファイルのツリーと各ファイルの役割]

## 🔄 処理フロー

### ユーザー操作 → 処理の流れ
[シーケンス図 ASCII]

1. [ステップ1の説明] → `ファイル名.dart:行数`
2. [ステップ2の説明] → `ファイル名.dart:行数`

## 🧩 主要なクラス・関数

### `クラス名` (ファイルパス)
- **役割**: 〇〇
- **重要なメソッド**:
  - `methodName()` — 何をするメソッドか
  
\`\`\`dart
// 実際のコードを引用
\`\`\`

## 📡 外部との接続
- API / Firebase: どのエンドポイントを使うか
- 他の機能との依存関係

## ⚠️ 実装上の注意点
[エラーハンドリング、エッジケース、パフォーマンスの考慮点]

## 🔧 この機能を拡張するには
[新しいサブ機能を追加するときの手順]
```

### Step 4: 既存インデックスの更新

`docs/learning/README.md` の機能一覧セクションに追記:

```markdown
## 機能別ドキュメント
- [{機能名}](features/{機能名}.md) - {生成日時}
```

## 品質基準

- 対象ファイルの **実際のコードを必ず引用** する（架空のコードを書かない）
- ファイル名と行番号を参照として記載する
- 「この実装はなぜこうなっているか」の考察を含める