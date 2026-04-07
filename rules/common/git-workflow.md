# Git Workflow — 共通ルール

## ブランチ戦略

```
main          # 本番リリース済み
develop       # 次のリリース準備
feature/xxx   # 機能開発
fix/xxx       # バグ修正
hotfix/xxx    # 緊急修正
release/x.x.x # リリース準備
```

## コミットメッセージ規則（Conventional Commits）

```
<type>(<scope>): <summary>

types:
  feat     新機能
  fix      バグ修正
  refactor リファクタリング（機能変更なし）
  test     テスト追加・修正
  docs     ドキュメント
  chore    ビルド・設定・依存関係
  perf     パフォーマンス改善
  style    フォーマット・空白（ロジック変更なし）
  ci       CI/CD 設定

例:
  feat(auth): ソーシャルログイン機能を追加
  fix(user): プロフィール更新時のクラッシュを修正
  refactor(cart): CartNotifier を Clean Architecture に対応
```

## コミットの原則

- 1コミット = 1つの論理的変更
- WIP コミットを main/develop にマージしない
- `--no-verify` フラグを使わない（CI を迂回しない）
- コミット前に `flutter analyze` と `flutter test` がグリーンであること

## PR のルール

- PR タイトルはコミットメッセージ規則に従う
- PR のサイズ: 変更 400行以内を目安（大きければ分割）
- レビュアーを必ず1名以上アサイン
- CI が全て通ってからマージ
- `main` への直接 push は禁止

## 禁止操作

- `git push --force` を main/develop に対して実行
- merge commit なしで squash して履歴を書き換える（レビュー済みコミットの場合）
- .env / keystore / 証明書ファイルの commit
