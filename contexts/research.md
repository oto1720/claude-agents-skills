# Research Context — Flutter

Mode: リサーチ・技術調査
Focus: ライブラリ選定・アーキテクチャ比較・ベストプラクティス調査

## 行動指針

- 公式ドキュメントを一次情報として優先する
- 複数の選択肢を比較してトレードオフを明示する
- 実際のコード例で検証する
- 調査結果は `docs/research/` に保存する

## リサーチフロー

```
1. 課題・要件の明確化
2. 公式ドキュメント・GitHub を確認
3. コミュニティの実績（pub.dev スコア・GitHub Stars・Issues）を確認
4. 小さなサンプルで動作検証
5. トレードオフを整理して提案
```

## Flutter 調査のポイント

### パッケージ選定基準

| 基準 | 確認方法 |
|------|---------|
| pub.dev スコア | `https://pub.dev/packages/{name}/score` |
| Flutter 対応バージョン | pubspec.yaml の environment.flutter |
| 最終更新 | pub.dev の "Published" 日付 |
| GitHub Stars / Issues | パッケージの homepage |
| Null Safety 対応 | pub.dev の "Dart 3 compatible" バッジ |

### 公式リソース

- Flutter 公式: `https://docs.flutter.dev`
- Dart 公式: `https://dart.dev/guides`
- pub.dev: `https://pub.dev`
- Flutter GitHub: `https://github.com/flutter/flutter`
- Flutter Cookbook: `https://docs.flutter.dev/cookbook`

## 調査テンプレート

```markdown
# 技術調査: {テーマ}

**調査日**: {date}
**調査者**: Claude Code / research context

## 背景・課題

{なぜ調査が必要か}

## 調査結果

### 選択肢A: {名前}

**メリット**:
- ...

**デメリット**:
- ...

**実績**: Stars: N / pub.dev score: N / 最終更新: YYYY-MM

### 選択肢B: {名前}

...

## 比較表

| 観点 | 選択肢A | 選択肢B |
|------|---------|---------|
| 学習コスト | 低/中/高 | ... |
| パフォーマンス | ... | ... |
| テスタビリティ | ... | ... |

## 推奨

**推奨**: {選択肢名}

**理由**: {理由}

**採用条件**: {どんなケースで採用するか}
```

## 参考リンク

- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture)
- [Riverpod ドキュメント](https://riverpod.dev)
- [BLoC ライブラリ](https://bloclibrary.dev)
- [go_router ドキュメント](https://pub.dev/packages/go_router)
- [Effective Dart](https://dart.dev/effective-dart)
