# Development Context — Flutter

Mode: アクティブな Flutter 開発
Focus: 実装・機能追加・バグ修正

## 行動指針

- コードを書いてから説明する（説明が先になりすぎない）
- 動く実装を優先する（完璧な設計より動くコード）
- 変更後は必ず `flutter analyze` と `flutter test` を実行する
- コミットはアトミックに（1コミット = 1つの論理変更）

## 優先順位

1. **動作する** — まず動くコードを書く
2. **正しい** — テストでロジックを検証する
3. **きれい** — リファクタリングで整理する

## 開発フロー

```
1. 要件確認 → 不明点は先に質問
2. アーキテクチャ確認 → flutter-architect エージェントを活用
3. TDD: テストを先に書く → 実装 → グリーン
4. flutter-reviewer でセルフレビュー
5. flutter analyze + flutter test がグリーンであること
6. コミット（Conventional Commits 形式）
```

## よく使うコマンド

```bash
flutter pub get                                              # 依存関係更新
flutter pub run build_runner build --delete-conflicting-outputs  # コード生成
dart format .                                               # フォーマット
flutter analyze                                             # 静的解析
flutter test --coverage                                     # テスト+カバレッジ
flutter test test/features/user/ --reporter=expanded        # 特定のテスト
flutter run -d chrome                                       # Web で実行
flutter run --profile                                       # パフォーマンス計測
```

## 使用するエージェント

| タスク | エージェント |
|--------|------------|
| 設計相談 | `flutter-architect` |
| コードレビュー | `flutter-reviewer` |
| ビルドエラー | `flutter-build-resolver` |
| テスト | `flutter-test-runner` |
| パフォーマンス | `flutter-performance-analyzer` |

## 現在の技術スタック（プロジェクトに合わせて更新）

- Flutter SDK: 3.x.x (stable)
- 状態管理: Riverpod 2.x
- ルーティング: go_router
- HTTP: Dio
- アーキテクチャ: Feature-first Clean Architecture
