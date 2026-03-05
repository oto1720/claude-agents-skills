---
name: isomorphism-check
description: |
  同型原理（Isomorphism Principle）に特化したコード一貫性チェックを実行する。
  AIが生成したコードがコードベース既存の「同じ役割・同じ形」の実装と一致しているか検証する。
  diffでは見えない比較対象を自動で探し出し、実装の形が揃っているかをチェックする。

  以下のトリガーで自動発動:
  - 「同型原理チェック」「同型チェック」「形が揃ってるか確認」
  - 「他の箇所と同じ書き方か確認」「既存パターンと合わせて」
  - 「isomorphism check」「isomorphism-check」
  - /isomorphism-check [ファイルパスまたはディレクトリ]
allowed-tools: Read, Glob, Grep, Bash, Write
---

# Isomorphism Check Skill

同型原理に特化して、変更コードと既存の類似実装の「形」が揃っているかをチェックする。

## 同型原理とは

> 同じ役割・構造・意味を持つコードは、コードベース全体で同じ「形」で書かれるべき

AIは局所最適に優れるが、コードベース全体のパターンを意識せずに実装する。
diff（差分）レビューでは「何が変わったか」しか見えず「他の箇所がどう書いているか」は見えない。

## チェック項目

| 観点 | 典型的な逸脱例 |
|------|-------------|
| 実装スタイル | 他はResult型を使うがここだけtry/catch |
| 命名パターン | 他は`fetchXxx`だがここだけ`getXxx` |
| 戻り値の型 | 他は`Future<Result<T>>`だがここだけ`T?` |
| 引数パターン | コールバックや高階関数の引数数・順序が他と違う |
| 数値・単位 | モジュール内でms/sec混在、px/rem混在 |
| 処理順序 | 初期化→処理→後処理の順序が他と異なる |
| エラー処理 | エラーの捕捉・変換・伝播のパターンが統一されていない |
| 依存・import | 同種の処理で異なるライブラリを使っている |

## 実行フロー

### Step 1: 変更コードの特定

`$ARGUMENTS` にファイルパスが指定された場合はそのファイルを対象にする。
未指定の場合はgit変更ファイルを取得する。

```bash
git diff HEAD --name-only 2>/dev/null
git diff --staged --name-only 2>/dev/null
```

変更ファイルを読み込み、どんな「役割」の実装が変更されたかを把握する。

### Step 2: 類似実装をコードベースから検索

変更コードの役割に対応するキーワードでgrepし、類似実装を3〜5件見つけて読み込む。

```bash
# 同種のクラス・メソッドを探す（例）
grep -rn "class.*Repository\|class.*Service\|class.*UseCase" --include="*.dart" --include="*.ts" . | head -30
grep -rn "fun fetch\|async fetch\|def fetch" --include="*.dart" --include="*.ts" --include="*.py" . | head -30

# エラーハンドリングパターン
grep -rn "Result\|Either\|catch\|try" --include="*.dart" --include="*.ts" . | head -40

# 非同期パターン
grep -rn "async\|await\|Future\|Promise" --include="*.dart" --include="*.ts" . | head -40
```

### Step 3: 形を比較する

変更コードと既存の類似実装を**並べて**比較し、「形の差異」を検出する。

同じ役割なのに形が違う箇所を列挙する。形が同じであれば OK と記録する。

### Step 4: 結果を出力

ターミナルに直接出力する（ファイル保存は不要）:

```
## 同型原理チェック結果

対象: {変更ファイル}
比較した類似実装: {参照ファイルリスト}

### 形の差異（要確認）

[差異1]
- 変更箇所: path/to/file.dart:42
  → try/catch でエラーを処理している

- 既存パターン: path/to/other.dart:15, path/to/another.dart:88
  → Result<T, Error> を返している

- 差異: エラーハンドリングの形が揃っていない
  推奨: Result型に統一するか、意図的な場合はコメントで理由を記載

---

[差異2]
...

### 形が揃っている箇所

- 命名パターン: fetchXxx の形で統一 OK
- 引数パターン: コールバックの形が統一 OK

---

逸脱: N件 / OK: N箇所
```

## 判断基準

以下の場合は指摘を「参考情報」として扱う（必須修正ではない）:
- コメントで逸脱の理由が明示されている
- 新パターンへの移行途中と文脈から判断できる
- 明らかに異なるレイヤー・ドメインで同型が不要な場合
