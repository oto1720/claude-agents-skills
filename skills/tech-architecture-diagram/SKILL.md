---
name: tech-architecture-diagram
description: プロジェクト全体の技術構成図（アーキテクチャダイアグラム）を自動生成するスキル。リポジトリやプロジェクトのコードベースを解析し、使用技術・依存関係・レイヤー構造・データフロー・インフラ構成を可視化したMermaid/SVG/HTML図を生成する。「技術構成図を作って」「アーキテクチャ図」「システム構成を可視化」「プロジェクトの全体像」「tech stack diagram」などのリクエストで必ずこのスキルを使用すること。プロジェクトの理解・オンボーディング資料・ドキュメント作成にも活用できる。
---

# Tech Architecture Diagram Generator

プロジェクトのコードベースを静的解析し、技術構成図を自動生成するスキル。

## 概要

このスキルは以下のステップで動作する：

1. **プロジェクト探索** — ファイル構造・設定ファイル・依存関係を走査
2. **技術スタック検出** — 言語・フレームワーク・ライブラリ・インフラを特定
3. **アーキテクチャ分析** — レイヤー構造・モジュール依存・データフローを推定
4. **図の生成** — Mermaid / SVG / HTML で可視化

## エージェント構成

このスキルは以下のエージェントを使い分ける（`agents/`ディレクトリ参照）：

| エージェント | 役割 |
|---|---|
| `scanner.md` | プロジェクト走査・技術スタック検出 |
| `analyzer.md` | アーキテクチャパターン分析・レイヤー推定 |
| `renderer.md` | 図の生成（Mermaid/SVG/HTML） |

## ワークフロー

### Step 1: プロジェクト走査

`agents/scanner.md` の手順に従い、以下を収集する：

```
対象ファイル（優先順）:
├── package.json / pubspec.yaml / go.mod / Cargo.toml / requirements.txt
├── docker-compose.yml / Dockerfile / fly.toml / vercel.json
├── .github/workflows/*.yml
├── ディレクトリ構造（2〜3階層）
├── 主要なソースファイルのimport文
└── README.md / docs/
```

**収集する情報：**
- 使用言語・フレームワーク・主要ライブラリ
- データベース・キャッシュ・メッセージキュー
- 外部API・サードパーティサービス
- CI/CD・デプロイ先
- テスト構成

### Step 2: アーキテクチャ分析

`agents/analyzer.md` の手順に従い、以下を推定する：

- **アーキテクチャパターン**: MVC / Clean Architecture / Monolith / Microservices / Serverless 等
- **レイヤー構造**: Presentation → Application → Domain → Infrastructure
- **モジュール依存関係**: どのモジュールがどのモジュールに依存しているか
- **データフロー**: リクエストの流れ、データの永続化パス
- **境界コンテキスト**: ドメイン駆動設計の場合のBounded Context

### Step 3: 図の生成

`agents/renderer.md` の手順に従い、出力形式を決定する：

| 出力形式 | 用途 |
|---|---|
| **Mermaid (.mermaid)** | GitHub/GitLab READMEへの埋め込み、軽量な共有 |
| **HTML (.html)** | インタラクティブな閲覧、ズーム・パン対応 |
| **SVG (.svg)** | 高品質な画像出力、ドキュメント埋め込み |

デフォルトは **HTML（インタラクティブ）** と **Mermaid（ドキュメント用）** の2つを同時生成。

### Step 4: 出力と共有

生成したファイルを `/mnt/user-data/outputs/` に配置し、`present_files` で共有する。

## 図の構成要素

生成する図には以下の要素を含める：

### 1. システム全体構成図 (System Overview)
- フロントエンド / バックエンド / データベース / 外部サービスの関係
- 通信プロトコル（HTTP/gRPC/WebSocket等）のラベル付き

### 2. 技術スタックマップ (Tech Stack Map)
- 各レイヤーで使用している具体的な技術名とバージョン
- カテゴリ別の整理（言語/FW/DB/Infra/CI等）

### 3. ディレクトリ・モジュール構造図 (Module Structure)
- 主要ディレクトリとその責務
- モジュール間の依存方向

### 4. データフロー図 (Data Flow) — オプション
- ユーザーリクエストからレスポンスまでの流れ
- データ永続化のパス

## デザインガイドライン

### Mermaid図
- `graph TD` または `graph LR` を使用
- サブグラフでレイヤーをグルーピング
- ノードの色分け: フロント(青系) / バック(緑系) / DB(オレンジ系) / 外部(灰色系)
- `classDef` でスタイルを定義

### HTML図
- D3.js または手書きSVG + CSSで実装
- ダークテーマベース（背景 #0d1117）
- ノードはカード型で角丸・ドロップシャドウ
- グループは破線の囲みで表現
- ホバーで詳細情報をツールチップ表示
- レスポンシブ対応

### 色彩パレット（推奨）
```
Frontend:    #61DAFB (React Blue) / #42B883 (Vue Green) / #3178C6 (TS Blue)
Backend:     #00ADD8 (Go Cyan) / #68A063 (Node Green) / #FF6F00 (Rust Orange)  
Database:    #F29111 (MySQL Orange) / #336791 (PostgreSQL Blue) / #4DB33D (MongoDB Green)
Infra:       #FF9900 (AWS Orange) / #4285F4 (GCP Blue) / #0078D4 (Azure Blue)
CI/CD:       #FC6D26 (GitLab Orange) / #2088FF (GitHub Actions Blue)
Default:     #8B949E (Gray) — カテゴリ不明時
```

## ユーザーとのインタラクション

1. プロジェクトのパスまたはファイルが提供されたら、まず走査を開始
2. 走査結果のサマリーを提示し、ユーザーに確認を取る
3. 図の生成方針（どの図を含めるか）を簡潔に提案
4. 図を生成して共有
5. フィードバックに基づいて修正

**対話のポイント：**
- 走査結果は簡潔に箇条書きで提示（冗長な説明を避ける）
- 技術的な推測が含まれる場合は明示する
- 複数のプロジェクト構成（モノレポ等）にも対応する

## 参考資料

- `references/detection-rules.md` — 技術スタック検出ルールの詳細
- `references/mermaid-templates.md` — Mermaid図のテンプレート集