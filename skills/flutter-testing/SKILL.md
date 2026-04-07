---
name: flutter-testing
description: Flutter の unit / widget / integration test の戦略・実装パターン・ベストプラクティス
---

# Flutter Testing

## いつ使うか

- テスト戦略を設計するとき
- unit / widget / integration test を書くとき
- テストが失敗してデバッグするとき
- カバレッジを改善するとき

---

## テストピラミッド

```
        /\
       /  \
      / E2E \      統合テスト（少数・遅い）
     /--------\
    /  Widget  \   Widget テスト（中程度）
   /------------\
  /  Unit Tests  \  Unit テスト（多数・高速）
 /________________\
```

**推奨比率**: Unit 70% / Widget 20% / Integration 10%

---

## Unit Test

### Repository のテスト

```dart
void main() {
  late UserRepository sut;
  late MockUserApiClient mockApiClient;
  late MockUserDao mockDao;

  setUp(() {
    mockApiClient = MockUserApiClient();
    mockDao = MockUserDao();
    sut = UserRepositoryImpl(
      apiClient: mockApiClient,
      dao: mockDao,
    );
  });

  group('getUser', () {
    test('APIから正常取得できる', () async {
      // Arrange
      final dto = UserDto(id: '1', name: 'Alice');
      when(() => mockApiClient.getUser('1')).thenAnswer((_) async => dto);

      // Act
      final result = await sut.getUser('1');

      // Assert
      expect(result, User(id: '1', name: 'Alice'));
      verify(() => mockApiClient.getUser('1')).called(1);
    });

    test('APIエラー時はキャッシュから返す', () async {
      // Arrange
      when(() => mockApiClient.getUser('1')).thenThrow(NetworkException());
      when(() => mockDao.getUser('1')).thenAnswer(
        (_) async => UserEntity(id: '1', name: 'Alice (cached)'),
      );

      // Act
      final result = await sut.getUser('1');

      // Assert
      expect(result.name, 'Alice (cached)');
    });
  });
}
```

### Riverpod Notifier のテスト

```dart
void main() {
  late ProviderContainer container;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loadUser 成功時に AsyncData が発行される', () async {
    // Arrange
    final user = User(id: '1', name: 'Alice');
    when(() => mockRepository.getUser('1')).thenAnswer((_) async => user);

    // Act
    final notifier = container.read(userNotifierProvider('1').notifier);

    // Assert: build() が呼ばれた後
    await container.read(userNotifierProvider('1').future);
    expect(
      container.read(userNotifierProvider('1')),
      isA<AsyncData<User>>().having((s) => s.value, 'value', user),
    );
  });
}
```

### BLoC のテスト

```dart
void main() {
  late UserBloc bloc;
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
    bloc = UserBloc(userRepository: mockRepository);
  });

  tearDown(() => bloc.close());

  blocTest<UserBloc, UserState>(
    'LoadUser イベントでユーザーが取得される',
    build: () => bloc,
    setUp: () {
      when(() => mockRepository.getUser('1'))
          .thenAnswer((_) async => User(id: '1', name: 'Alice'));
    },
    act: (bloc) => bloc.add(const LoadUser('1')),
    expect: () => [
      const UserLoading(),
      UserLoaded(User(id: '1', name: 'Alice')),
    ],
  );

  blocTest<UserBloc, UserState>(
    'APIエラー時に UserError が発行される',
    build: () => bloc,
    setUp: () {
      when(() => mockRepository.getUser('1'))
          .thenThrow(Exception('Network error'));
    },
    act: (bloc) => bloc.add(const LoadUser('1')),
    expect: () => [
      const UserLoading(),
      isA<UserError>(),
    ],
  );
}
```

---

## Widget Test

### 基本パターン

```dart
void main() {
  group('UserCard', () {
    testWidgets('ユーザー名が表示される', (tester) async {
      // Arrange
      const user = User(id: '1', name: 'Alice', role: 'Admin');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserCard(user: user),
          ),
        ),
      );

      // Assert
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('タップで onTap が呼ばれる', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: const User(id: '1', name: 'Alice'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserCard));
      expect(tapped, isTrue);
    });
  });
}
```

### Riverpod Provider を差し替えたテスト

```dart
testWidgets('ユーザー取得中はローディングが表示される', (tester) async {
  final container = ProviderContainer(
    overrides: [
      // Provider を差し替えてローディング状態を再現
      userNotifierProvider('1').overrideWith(
        () => AsyncNotifier.fromValue(const AsyncLoading<User>()),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: UserScreen(userId: '1')),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### ゴールデンテスト（UI スナップショット）

```dart
testWidgets('UserCard のゴールデンテスト', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: UserCard(user: User(id: '1', name: 'Alice')),
      ),
    ),
  );

  await expectLater(
    find.byType(UserCard),
    matchesGoldenFile('goldens/user_card.png'),
  );
});
```

---

## Integration Test

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ログインからホーム画面への遷移', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // ログイン画面が表示される
    expect(find.byType(LoginScreen), findsOneWidget);

    // メールとパスワードを入力
    await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'password');

    // ログインボタンをタップ
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ホーム画面に遷移
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
```

---

## テスト実行コマンド

```bash
# 全テスト
flutter test

# カバレッジ付き
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 特定ファイル
flutter test test/features/user/user_notifier_test.dart

# ゴールデンテスト更新
flutter test --update-goldens

# Integration test
flutter test integration_test/app_test.dart
```

---

## チェックリスト

- [ ] AAA（Arrange/Act/Assert）パターンで書く
- [ ] テスト名は「〜の場合に〜が起きる」形式の日本語
- [ ] setUp/tearDown で初期化・クリーンアップ
- [ ] モックは mocktail を使用
- [ ] Widget テストは MaterialApp で wrap
- [ ] Riverpod テストは ProviderContainer を使用
- [ ] カバレッジ 80% 以上を目標
