# Flutter Testing Rules

## テスト環境セットアップ

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0          # モック生成
  riverpod_test: ^2.0.0     # Riverpod テスト用
  bloc_test: ^9.0.0         # BLoC テスト用（使用時）
  golden_toolkit: ^0.15.0   # ゴールデンテスト（オプション）
```

## Widget テストの必須ラッパー

```dart
// ❌ Directionality エラーが発生
await tester.pumpWidget(UserCard(user: user));

// ✅ MaterialApp でラップ
await tester.pumpWidget(
  MaterialApp(home: UserCard(user: user)),
);

// ✅ Riverpod を使う Widget は ProviderScope でラップ
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      userRepositoryProvider.overrideWithValue(mockRepository),
    ],
    child: const MaterialApp(home: UserScreen()),
  ),
);
```

## pump の使い分け

```dart
// pump(): 1フレーム進める（アニメーション非完了）
await tester.pump();

// pump(duration): 指定時間分フレームを進める
await tester.pump(const Duration(seconds: 1));

// pumpAndSettle(): アニメーション・非同期処理が全て完了するまで待つ
// ⚠️ 無限アニメーションがあると timeout する
await tester.pumpAndSettle();

// 非同期 Provider の完了を待つ
await tester.pumpWidget(widget);
await tester.pump(); // 最初のフレーム
// または
await tester.pumpAndSettle(const Duration(seconds: 3));
```

## Finder の使い方

```dart
// テキストで検索
expect(find.text('Hello'), findsOneWidget);
expect(find.text('Error'), findsNothing);

// 型で検索
expect(find.byType(CircularProgressIndicator), findsOneWidget);

// Key で検索（テスト専用 Key を Widget に付ける）
expect(find.byKey(const Key('submit_button')), findsOneWidget);

// Icon で検索
expect(find.byIcon(Icons.favorite), findsOneWidget);

// カスタム Finder
expect(
  find.byWidgetPredicate((widget) => widget is Text && (widget.data?.contains('Error') ?? false)),
  findsOneWidget,
);
```

## mocktail の使い方

```dart
// Mock クラスの定義
class MockUserRepository extends Mock implements UserRepository {}

// セットアップ
late MockUserRepository mockRepository;
setUp(() {
  mockRepository = MockUserRepository();
});

// スタブの設定
when(() => mockRepository.getUser('1'))
    .thenAnswer((_) async => User(id: '1', name: 'Alice'));

// エラーのスタブ
when(() => mockRepository.getUser('1'))
    .thenThrow(NetworkException('Connection failed'));

// void メソッドのスタブ
when(() => mockRepository.deleteUser('1'))
    .thenAnswer((_) async {});

// 呼び出しの検証
verify(() => mockRepository.getUser('1')).called(1);
verifyNever(() => mockRepository.deleteUser(any()));
```

## ゴールデンテスト

```dart
testWidgets('UserCard のゴールデンテスト', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: UserCard(user: testUser)),
    ),
  );

  // 初回実行: --update-goldens フラグで PNG を生成
  // 以降: 差分を自動検出
  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});

// ゴールデンファイル更新
// flutter test --update-goldens
```

## 禁止事項

| 禁止 | 理由 | 代替 |
|------|------|------|
| `await Future.delayed()` でタイミング調整 | 不安定なテスト | `pumpAndSettle` / `pump(duration)` |
| テスト間での状態共有 | テストの独立性が崩れる | `setUp` で毎回初期化 |
| 本番の API を叩くテスト | 外部依存・不安定 | モックで差し替え |
| `print()` をテストのデバッグに使う | ノイズ | `debugPrint()` または削除 |
| テストで `expect` なし | 何もチェックしていない | 必ず `expect` を書く |
