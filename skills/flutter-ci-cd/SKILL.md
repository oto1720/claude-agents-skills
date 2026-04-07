---
name: flutter-ci-cd
description: Flutter の CI/CD（GitHub Actions / Fastlane / Codemagic）の設定・ベストプラクティス
---

# Flutter CI/CD

## いつ使うか

- CI/CD パイプラインを構築するとき
- GitHub Actions ワークフローを設定するとき
- 自動テスト・ビルド・デプロイを設定するとき
- App Store / Play Store への自動リリースを設定するとき

---

## GitHub Actions: 基本的な CI ワークフロー

```yaml
# .github/workflows/ci.yml
name: Flutter CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    name: Test & Analyze
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate code
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Analyze
        run: flutter analyze --fatal-infos

      - name: Run tests
        run: flutter test --coverage --reporter=github

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage/lcov.info
```

---

## GitHub Actions: Android ビルド

```yaml
# .github/workflows/android.yml
name: Android Build

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-android:
    name: Build Android APK/AAB
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          cache: true

      - name: Setup keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
          echo "storeFile=keystore.jks" >> android/key.properties
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: release-aab
          path: build/app/outputs/bundle/release/*.aab
```

---

## GitHub Actions: iOS ビルド

```yaml
# .github/workflows/ios.yml
name: iOS Build

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-ios:
    name: Build iOS IPA
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
          cache: true

      - name: Install CocoaPods
        run: |
          cd ios
          pod install

      - name: Import signing certificates
        uses: apple-actions/import-codesign-certs@v3
        with:
          p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
          p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

      - name: Download provisioning profiles
        uses: apple-actions/download-provisioning-profiles@v3
        with:
          bundle-id: com.example.myapp
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}

      - name: Build IPA
        run: flutter build ipa --release

      - name: Upload IPA
        uses: actions/upload-artifact@v4
        with:
          name: release-ipa
          path: build/ios/ipa/*.ipa
```

---

## Fastlane（iOS/Android 自動デプロイ）

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    run_tests(workspace: "Runner.xcworkspace", scheme: "Runner")
  end

  desc "Deploy to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_testflight(
      api_key_path: "fastlane/api_key.json",
      skip_waiting_for_build_processing: true
    )
  end

  desc "Deploy to App Store"
  lane :release do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      export_method: "app-store"
    )
    upload_to_app_store(
      api_key_path: "fastlane/api_key.json",
      submit_for_review: true,
      automatic_release: false
    )
  end
end

platform :android do
  desc "Deploy to Play Store Internal"
  lane :internal do
    sh("flutter build appbundle --release")
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
      json_key: 'fastlane/play-store-key.json'
    )
  end
end
```

---

## バージョン管理自動化

```yaml
# pubspec.yaml での自動バージョン更新
# CI でビルド番号を GitHub Actions run number に設定

- name: Update version
  run: |
    VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
    sed -i "s/version: .*/version: $VERSION+${{ github.run_number }}/" pubspec.yaml
```

---

## Secrets 管理

| Secret | 用途 |
|--------|------|
| `KEYSTORE_BASE64` | Android 署名キーストア（Base64） |
| `KEYSTORE_PASSWORD` | キーストアパスワード |
| `KEY_ALIAS` | キーエイリアス |
| `KEY_PASSWORD` | キーパスワード |
| `CERTIFICATES_P12` | iOS 署名証明書（Base64） |
| `APPSTORE_API_KEY_ID` | App Store Connect API キー ID |
| `APPSTORE_API_PRIVATE_KEY` | App Store Connect API 秘密鍵 |
| `PLAY_STORE_JSON_KEY` | Google Play Service Account JSON |

---

## チェックリスト

- [ ] PR に対して自動テストが走る
- [ ] `flutter analyze` でエラーがないことを確認
- [ ] カバレッジレポートが生成される
- [ ] main ブランチへのマージでビルドが走る
- [ ] シークレットは GitHub Secrets で管理
- [ ] keystore / 証明書をリポジトリに含めない（.gitignore）
- [ ] ビルド番号が自動インクリメント
