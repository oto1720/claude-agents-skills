---
name: code-learner
description: |
  既存のプロジェクトやコードベースを解析して、学習用のMarkdownドキュメントを自動生成する。
  以下のトリガーで自動発動:
  - 「このコードを教えて」「コードを解説して」「勉強したい」
  - 「プロジェクトを理解したい」「アーキテクチャを学びたい」
  - 「学習用のドキュメントを作って」「コードの説明ドキュメント」
  - /code-learner コマンド
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Code Learner Skill

既存のプロジェクトを解析して、エンジニアが効果的に学習できる **学習用Markdownドキュメント** を生成する。

## 実行フロー

### Step 1: プロジェクト全体スキャン

まずプロジェクトの全体像を把握する:

```bash
# ディレクトリ構造を取得
find . -type f \( -name "*.dart" -o -name "*.go" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.py" -o -name "*.swift" -o -name "*.kt" \) \
  | grep -v -E "(node_modules|.dart_tool|build|dist|.git|vendor)" \
  | head -100
```

次に重要なファイルを特定:
- `pubspec.yaml`, `go.mod`, `package.json`, `requirements.txt` → 依存関係
- `README.md` → プロジェクト概要
- `lib/`, `src/`, `cmd/` などのソースルート
- エントリポイント (`main.dart`, `main.go`, `index.ts` など)

### Step 2: アーキテクチャ解析

以下の観点でコードを読む:

1. **レイヤー構造** - Clean Architecture, MVC, MVVM など
2. **状態管理** - Riverpod, Bloc, Redux, Context など  
3. **データフロー** - どこからデータが来て、どこに行くか
4. **主要なクラス・関数** - 核心となるロジック

```bash
# Dart/Flutterの場合: レイヤーを確認
find lib -type d | sort

# Go の場合: パッケージ構造
find . -name "*.go" | xargs grep "^package " | sort -u

# 依存性注入 / Provider パターン
grep -r "Provider\|riverpod\|GetIt\|injectable" lib --include="*.dart" -l
```

### Step 3: 学習MDファイルの生成

解析結果を元に `docs/learning/` に以下のファイルを生成する:

#### 必須生成ファイル

**`docs/learning/00_overview.md`** — プロジェクト全体図
```
# プロジェクト概要
## 何を作っているか
## 技術スタック
## ディレクトリ構造（ツリー + 各ディレクトリの役割説明）
## データフロー図（ASCII アート）
```

**`docs/learning/01_architecture.md`** — アーキテクチャ解説
```
# アーキテクチャ解説　
## 採用しているパターン（例: Clean Architecture）
## 各レイヤーの責任
## レイヤー間の依存関係図　mermaidで制作
## なぜこの設計にしているか（推測・解説）
```

**`docs/learning/02_data_flow.md`** — データの流れ
```
# データフロー解説　mermaidで制作
## ユーザー操作からUI更新までの流れ
## APIコール / Firebaseアクセスのパターン
## 状態管理の仕組み
## シーケンス図（ASCII）
```

**`docs/learning/03_key_concepts.md`** — 重要概念の解説
```
# 重要な実装パターン
## プロジェクト固有のパターン
## よく使われるユーティリティ・Helper
## 命名規則・コーディング規約
## 初学者がつまずきやすいポイント
```

**`docs/learning/04_getting_started.md`** — 開発スタートガイド
```
# 開発を始めるには
## セットアップ手順
## 新機能を追加する手順（ステップバイステップ）
## よくあるタスクのパターン（例: 新しい画面の追加）
## デバッグのヒント
```

### Step 4: インデックスファイル生成

最後に `docs/learning/README.md` を生成:

```markdown
# 📚 コードベース学習ガイド

このドキュメントは [skill: code-learner] によって自動生成されました。

## 読む順番
1. [00_overview.md](00_overview.md) - まずここから
2. [01_architecture.md](01_architecture.md) - 設計を理解する
3. [02_data_flow.md](02_data_flow.md) - データの流れを追う
4. [03_key_concepts.md](03_key_concepts.md) - 重要パターンを学ぶ
5. [04_getting_started.md](04_getting_started.md) - 実際に手を動かす

生成日時: {date}
```

## 品質基準

生成するドキュメントは以下を満たす:

- **具体的なコードを引用する** - 抽象的な説明だけでなく実際のコードを示す
- **「なぜ」を説明する** - What だけでなく Why を記載する
- **ASCII図を使う** - データフロー、依存関係を視覚化する
- **初学者目線** - 前提知識を明示し、専門用語は説明する
- **実例ベース** - プロジェクト内の実際のコードから例を取る

## 出力完了メッセージ

生成完了後:
```
✅ 学習ドキュメントを docs/learning/ に生成しました

📁 docs/learning/
  ├── README.md          # インデックス・読む順番
  ├── 00_overview.md     # プロジェクト全体図
  ├── 01_architecture.md # アーキテクチャ解説
  ├── 02_data_flow.md    # データフロー
  ├── 03_key_concepts.md # 重要概念
  └── 04_getting_started.md # 開発スタートガイド
```
