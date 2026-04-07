# Flutter Project — Claude Code ハーネス設定

このディレクトリを Flutter プロジェクトとして Claude Code を使う際の設定です。

---

## エージェントカタログ

| エージェント | 用途 | トリガー例 |
|------------|------|-----------|
| `flutter-architect` | アーキテクチャ設計・技術判断 | 「Flutter の設計をして」「状態管理を選んで」 |
| `flutter-reviewer` | コードレビュー | 「Flutter コードをレビューして」「Widget を見て」 |
| `flutter-build-resolver` | ビルドエラー修復 | 「pub get が失敗した」「ビルドエラーを直して」 |
| `flutter-test-runner` | テスト実行・作成 | 「テストを書いて」「widget test を実行して」 |
| `flutter-performance-analyzer` | パフォーマンス改善 | 「アプリが重い」「rebuild を最適化して」 |

---

## スキルカタログ

| スキル | 内容 |
|--------|------|
| `flutter-widget-design` | Widget 設計・分割・composition |
| `flutter-state-management` | Riverpod / BLoC のベストプラクティス |
| `flutter-testing` | unit / widget / integration test 戦略 |
| `flutter-architecture` | Clean Architecture / Feature-first 構成 |
| `flutter-performance` | const・rebuild 削減・メモリ最適化 |
| `flutter-ci-cd` | GitHub Actions / Fastlane / Codemagic |

---

## 開発原則

### コーディング規則

1. **const を徹底する** — 変更されない Widget には必ず `const` を付ける
2. **Widget を分割する** — `build()` が50行を超えたら分割する
3. **ビジネスロジックを Widget に書かない** — Notifier / UseCase に移動する
4. **null! を使わない** — 適切な null チェックまたは late を使う
5. **print() を使わない** — `debugPrint()` または Logger パッケージを使う

### アーキテクチャ規則

1. **Feature-first 構成** — `lib/features/{feature}/data|domain|presentation`
2. **依存方向を守る** — `presentation → domain ← data`
3. **Domain は純粋 Dart** — Flutter / 外部ライブラリに依存しない
4. **Repository はインターフェースを通じて使う** — 直接実装クラスを参照しない

### テスト規則

1. **テストを先に書く（TDD 推奨）**
2. **Unit Test カバレッジ 80% 以上**
3. **Widget テストで主要な画面を網羅する**
4. **モックは mocktail を使用する**

### セキュリティ規則

1. **API キー・シークレットをコードに書かない** — `flutter_dotenv` または環境変数
2. **機密情報は flutter_secure_storage に保存する**
3. **HTTP（非HTTPS）を使わない**
4. **ログに個人情報を出力しない**

---

## 推奨パッケージ

```yaml
dependencies:
  # 状態管理 + hooks（推奨）
  hooks_riverpod: ^2.x.x       # flutter_hooks + riverpod の統合
  riverpod_annotation: ^2.x.x
  flutter_hooks: ^0.20.x       # hooks_riverpod に含まれるが明示的に追加推奨

  # ルーティング
  go_router: ^13.x.x

  # HTTP
  dio: ^5.x.x

  # ローカルDB
  drift: ^2.x.x  # または hive_flutter

  # 画像キャッシュ
  cached_network_image: ^3.x.x

  # 環境変数
  flutter_dotenv: ^5.x.x

  # 安全なストレージ
  flutter_secure_storage: ^9.x.x

  # ロギング
  logger: ^2.x.x

dev_dependencies:
  # コード生成
  build_runner: ^2.x.x
  riverpod_generator: ^2.x.x

  # テスト
  mocktail: ^1.x.x
  bloc_test: ^9.x.x  # BLoC 使用時

  # Linter
  flutter_lints: ^4.x.x
  custom_lint: ^0.x.x
  riverpod_lint: ^2.x.x
```

---

## よく使うコマンド

```bash
# コード生成
dart run build_runner build --delete-conflicting-outputs

# 全テスト実行
flutter test --coverage

# 静的解析
flutter analyze

# フォーマット
dart format .

# Android ビルド
flutter build apk --release
flutter build appbundle --release

# iOS ビルド
flutter build ipa --release

# Web ビルド
flutter build web --release
```

---

## analysis_options.yaml 推奨設定

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # const を強制
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
    prefer_const_declarations: true

    # コード品質
    avoid_print: true
    avoid_unnecessary_containers: true
    use_super_parameters: true
    prefer_final_locals: true

    # null safety
    avoid_null_checks_in_equality_operators: true

analyzer:
  errors:
    avoid_print: error
    prefer_const_constructors: warning
```
