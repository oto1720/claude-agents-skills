# Testing — 全言語共通ルール

## テストの原則

- **テストファースト** — 実装前にテストを書く（TDD）
- **FIRST 原則**: Fast / Independent / Repeatable / Self-validating / Timely
- **AAA パターン**: Arrange（準備）/ Act（実行）/ Assert（検証）を明確に分ける
- **1テスト1アサーション** — 失敗理由を明確にする

## テスト命名規則

```
// ✅ 良い例: 「状況」「操作」「期待結果」で表現
'ユーザーが存在しない場合に getUser が NotFoundException を投げる'
'有効なメールと正しいパスワードでログインに成功する'

// ❌ 悪い例
'test1'
'getUser test'
'should work'
```

## カバレッジ目標

| レイヤー | 目標カバレッジ |
|---------|--------------|
| Domain (UseCase/Entity) | 90%以上 |
| Data (Repository) | 80%以上 |
| Presentation (Notifier/BLoC) | 80%以上 |
| UI (Widget/Screen) | 主要フローのみ |

## モックの原則

- 外部依存（API・DB・ファイルシステム）のみモック
- 内部実装をモックしない
- モックの設定は最小限に
- テスト後にモックをリセットする

## テストデータ

- テストデータはテスト内に直接定義（外部ファイルから読み込まない）
- 境界値を必ずテストする（0, 1, max, null, 空文字列）
- 本番データをテストに使わない

## 禁止事項

- `Thread.sleep` / `await Future.delayed` でタイミングを誤魔化さない
- `try/catch` でテスト失敗を握りつぶさない
- テスト間で状態を共有しない（各テストは独立）
