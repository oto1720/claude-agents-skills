# claude-agents-skills

Flutter用の場合
```
 claude-agents-skills/
  ├── agents/
  │   ├── flutter-architect.md          # 設計・アーキテクチャ (opus)
  │   ├── flutter-reviewer.md           # コードレビュー 7観点
  │   ├── flutter-build-resolver.md     # ビルドエラー修復
  │   ├── flutter-test-runner.md        # テスト実行・生成
  │   └── flutter-performance-analyzer.md  # パフォーマンス最適化
  ├── skills/
  │   ├── flutter-widget-design/        # Widget 設計・const・State Hoisting
  │   ├── flutter-state-management/     # Riverpod / BLoC
  │   ├── flutter-testing/              # unit / widget / integration
  │   ├── flutter-architecture/         # Clean Architecture
  │   ├── flutter-performance/          # rebuild 削減・メモリ
  │   └── flutter-ci-cd/               # GitHub Actions / Fastlane
  ├── rules/
  │   ├── common/                       # coding-style / testing / security /
  │   │   │                             # git-workflow / performance / agents / code-review
  │   ├── dart/                         # style / async
  │   └── flutter/                      # widgets / state-management / testing
  ├── hooks/
  │   └── hooks.json                    # 17個のフック（SessionStart/Pre/Post/Stop）
  ├── contexts/
  │   ├── dev.md                        # 実装モード
  │   ├── research.md                   # 調査モード
  │   └── review.md                     # レビューモード（7観点チェックリスト）
  └── tests/
      ├── run-all.sh                    # 全バリデーション実行
      ├── validate-agents.sh            # エージェント構造検証
      ├── validate-skills.sh            # スキル構造検証
      ├── validate-hooks.sh             # hooks.json 構造検証
      └── validate-rules.sh             # rules ファイル検証


```
hooks.json の主なフック:
  - post:edit:dart-format — Dart 編集後に自動フォーマット
  - post:edit:flutter-analyze — 静的解析（エラー/警告のみ表示）
  - post:edit:test-reminder — テストファイル未作成の警告
  - post:edit:secrets-detect — 機密情報ハードコード検出
  - pre:bash:block-no-verify — --no-verify をブロック
  - pre:bash:block-force-push — main/develop への force push をブロック
  - stop:flutter-quality — セッション終了時に全変更ファイルをフォーマット・解析