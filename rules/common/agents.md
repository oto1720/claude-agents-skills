# Agent Rules — エージェント利用の共通ルール

## エージェント委譲の原則

### いつエージェントに委譲するか

- ドメイン専門知識が必要なタスク → 専門エージェントへ
- レビューが必要なコード変更 → `flutter-reviewer` へ
- アーキテクチャ判断 → `flutter-architect` へ
- ビルドエラー → `flutter-build-resolver` へ
- テスト作成・実行 → `flutter-test-runner` へ
- パフォーマンス問題 → `flutter-performance-analyzer` へ

### エージェントへの指示の書き方

```
# 良い例: 具体的・スコープ明確
「lib/features/user/ ディレクトリの Flutter コードをレビューして。
特に Riverpod の使い方と Widget 分割が適切か確認して。」

# 悪い例: 曖昧・スコープ不明確
「コードを見て」
```

## エージェントの出力の扱い

- エージェントのレビュー結果は `docs/reviews/` に保存する
- アーキテクチャ設計書は `docs/architecture/` に保存する
- 重要な設計決定は ADR（Architecture Decision Record）として記録する

## 禁止事項

- エージェントの提案を無検証で適用しない
- Critical 指摘を無視してマージしない
- エージェント同士を競合する指示で同時実行しない（同じファイルへの並列編集）
