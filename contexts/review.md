# Review Context — Flutter

Mode: コードレビュー・品質確認
Focus: バグ検出・アーキテクチャ・パフォーマンス・セキュリティ

## 行動指針

- 実際のコードを必ず読んでからレビューする（推測でレビューしない）
- 問題点は必ず修正コードを示す（「直してください」は不可）
- なぜ問題かを説明する（WHY を重視）
- 良い点も必ず挙げる（建設的なレビュー）
- `flutter-reviewer` エージェントを積極的に活用する

## レビューフロー

```
1. git diff でスコープ確認
2. 関連ファイルを読む（Widget → Notifier → Repository → UseCase）
3. 7観点でチェック（→ 下記参照）
4. 重要度で分類（Critical / Major / Minor / Good）
5. レポートを docs/reviews/ に保存
6. Critical がゼロになってから APPROVE
```

## 7つのレビュー観点

### 1. アーキテクチャ（最重視）

- [ ] Feature-first Clean Architecture のレイヤー違反がない
- [ ] `presentation → domain ← data` の依存方向が正しい
- [ ] Widget にビジネスロジックがない
- [ ] Repository Interface が Domain に定義されている

### 2. Dart コード品質

- [ ] `!`（null assertion）の多用がない
- [ ] `dynamic` を使っていない
- [ ] `print()` を使っていない（`debugPrint()` を使う）
- [ ] `const` が適切に使われている

### 3. Widget 設計

- [ ] `const` Widget が使われている
- [ ] `build()` が50行以内
- [ ] `build()` 内に重い処理がない
- [ ] 不要な `StatefulWidget` がない
- [ ] `mounted` チェックが async の後にある

### 4. 状態管理（Riverpod / BLoC）

- [ ] `state` を直接変更していない（immutable update）
- [ ] `ref.watch` / `ref.read` / `ref.listen` が正しく使われている
- [ ] `autoDispose` が適切に設定されている
- [ ] エラー状態・ローディング状態が定義されている

### 5. メモリ・ライフサイクル

- [ ] `TextEditingController` / `AnimationController` が `dispose` されている
- [ ] `StreamSubscription` が `cancel` されている
- [ ] `Timer` が `cancel` されている
- [ ] `FocusNode` が `dispose` されている

### 6. テスト

- [ ] 新しいロジックにテストがある
- [ ] Unit Test カバレッジ 80% 以上
- [ ] Widget Test で主要な画面をカバー
- [ ] エラーケース・境界値がテストされている

### 7. セキュリティ

- [ ] APIキー・パスワードがハードコードされていない
- [ ] HTTP（非HTTPS）が使われていない
- [ ] ログに個人情報が出力されていない
- [ ] ユーザー入力がバリデーションされている

## 重要度の判定

| レベル | 基準 | 対応 |
|--------|------|------|
| 🔴 Critical | セキュリティ脆弱性・メモリリーク・クラッシュ・レイヤー違反 | マージ前に必ず修正 |
| 🟠 Major | バグの可能性・テスト不足・パフォーマンス問題 | 早急に対応 |
| 🟡 Minor | コード品質・命名・const 最適化 | 改善推奨 |
| 🟢 Good | 良い実装・参考になるパターン | 称賛・共有 |

## レポート保存先

```bash
docs/reviews/flutter_review_{YYYYMMDD_HHmmss}.md
```
