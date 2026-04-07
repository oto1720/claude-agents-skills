---
name: flutter-state-management
description: Flutter の状態管理（Riverpod / hooks_riverpod / BLoC / Provider）のベストプラクティスと選択基準
---

# Flutter State Management

## いつ使うか

- 状態管理ライブラリを選定するとき
- Riverpod の Provider を設計するとき
- hooks_riverpod で Widget ローカル状態を管理するとき
- BLoC の Event/State を設計するとき
- 状態管理のバグを調査するとき

---

## 選択基準

| 状況 | 推奨 | 理由 |
|------|------|------|
| 新規プロジェクト（小〜中規模） | hooks_riverpod | 型安全・StatefulWidget 不要・簡潔 |
| 大規模チーム・複雑なビジネスロジック | BLoC | 明示的な状態遷移・テスタブル |
| 既存 Provider からの移行 | Riverpod | API が近く移行しやすい |
| hooks が使えない環境 | flutter_riverpod | hooks なしの純粋 Riverpod |
| 学習目的・プロト | Provider | 学習コスト最低 |

---

## Riverpod ベストプラクティス

### Provider の設計

```dart
// ✅ コード生成を使った Notifier
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String userId) async {
    // autoDispose はデフォルトで有効（@riverpod）
    return ref.watch(userRepositoryProvider).getUser(userId);
  }

  Future<void> updateName(String name) async {
    final current = await future; // 現在の値を取得
    state = AsyncData(current.copyWith(name: name));
    await ref.read(userRepositoryProvider).updateUser(current.copyWith(name: name));
  }
}

// ✅ 純粋なデータ取得は @riverpod の関数形式
@riverpod
Future<List<User>> users(UsersRef ref) async {
  return ref.watch(userRepositoryProvider).getUsers();
}

// ✅ 同期的な計算
@riverpod
int totalPrice(TotalPriceRef ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.price);
}
```

### UI での使い方

```dart
class UserScreen extends ConsumerWidget {
  const UserScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ AsyncValue.when でローディング/エラー/データを安全に処理
    final userAsync = ref.watch(userNotifierProvider(userId));

    return userAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(userNotifierProvider(userId)),
      ),
      data: (user) => UserProfile(user: user),
    );
  }
}
```

### select で部分 watch

```dart
// ❌ State 全体を watch → name 以外の変更でも rebuild
final user = ref.watch(userProvider);
Text(user.name)

// ✅ 必要なフィールドだけ watch → name が変わったときのみ rebuild
final name = ref.watch(userProvider.select((u) => u.name));
Text(name)
```

### Provider の依存グラフ設計

```dart
// ✅ 正しい依存の向き（データ → ロジック → UI）
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(
    apiClient: ref.watch(apiClientProvider),
    db: ref.watch(databaseProvider),
  );
}

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String id) {
    return ref.watch(userRepositoryProvider).getUser(id);
  }
}
```

---

## BLoC ベストプラクティス

### Event / State の設計

```dart
// ✅ Sealed class で網羅的な Event 定義
sealed class UserEvent {
  const UserEvent();
}

class LoadUser extends UserEvent {
  const LoadUser(this.id);
  final String id;
}

class UpdateUserName extends UserEvent {
  const UpdateUserName(this.name);
  final String name;
}

// ✅ Sealed class で網羅的な State 定義
sealed class UserState {
  const UserState();
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserLoaded extends UserState {
  const UserLoaded(this.user);
  final User user;
}

class UserError extends UserState {
  const UserError(this.message);
  final String message;
}
```

### BLoC の実装

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc({required this.userRepository}) : super(const UserInitial()) {
    on<LoadUser>(_onLoadUser);
    on<UpdateUserName>(_onUpdateUserName);
  }

  final UserRepository userRepository;

  Future<void> _onLoadUser(LoadUser event, Emitter<UserState> emit) async {
    emit(const UserLoading());
    try {
      final user = await userRepository.getUser(event.id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
```

### UI での使い方

```dart
class UserScreen extends StatelessWidget {
  const UserScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserBloc(
        userRepository: context.read<UserRepository>(),
      )..add(LoadUser(userId)),
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) => switch (state) {
          UserInitial() => const SizedBox.shrink(),
          UserLoading() => const CircularProgressIndicator(),
          UserLoaded(:final user) => UserProfile(user: user),
          UserError(:final message) => ErrorView(message: message),
        },
      ),
    );
  }
}
```

---

## hooks_riverpod ベストプラクティス

`hooks_riverpod` = `flutter_hooks` + `flutter_riverpod` の統合パッケージ。
**StatefulWidget をほぼ不要にする**のが最大の利点。

### セットアップ

```yaml
dependencies:
  hooks_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x

dev_dependencies:
  build_runner: ^2.x.x
  riverpod_generator: ^2.x.x
```

### HookConsumerWidget — 基本形

```dart
// ❌ hooks_riverpod なし: StatefulWidget が必要
class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}
class _SearchScreenState extends State<SearchScreen> {
  late final _controller = TextEditingController();
  late final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) { ... }
}

// ✅ HookConsumerWidget: StatefulWidget 不要・dispose も自動
class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // コントローラーは自動 dispose される
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final results = ref.watch(searchResultsProvider);

    return TextField(
      controller: controller,
      focusNode: focusNode,
    );
  }
}
```

### 主要 Hooks の使い分け

```dart
class ExampleWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // useState: Widget ローカルの単純な状態（UI のみ）
    final isExpanded = useState(false);
    final count = useState(0);

    // useTextEditingController: 自動 dispose
    final searchController = useTextEditingController(text: 'initial');

    // useAnimationController: 自動 dispose・duration 指定
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // useMemoized: 高コストな計算をキャッシュ（依存配列が変わるまで再計算しない）
    final filteredItems = useMemoized(
      () => items.where((e) => e.isActive).toList(),
      [items], // 依存: items が変わったら再計算
    );

    // useEffect: initState/dispose 相当のサイドエフェクト
    useEffect(() {
      // 初回実行（initState 相当）
      analyticsService.logScreenView('example');

      // クリーンアップ（dispose 相当）
      return () => analyticsService.logScreenExit('example');
    }, []); // [] = 初回のみ実行

    // useEffect: 依存値が変わったら再実行
    final userId = ref.watch(currentUserProvider).id;
    useEffect(() {
      ref.read(userNotifierProvider(userId).notifier).refresh();
      return null; // クリーンアップ不要
    }, [userId]);

    // useRef: mutable な値を保持（rebuild してもリセットされない）
    final previousCount = useRef(0);

    return Column(children: [
      Text('${count.value}'),
      ElevatedButton(
        onPressed: () {
          previousCount.value = count.value;
          count.value++;
        },
        child: const Text('Increment'),
      ),
      if (isExpanded.value) const ExpandedContent(),
    ]);
  }
}
```

### useState vs Riverpod Notifier の使い分け

```dart
// ✅ useState: Widget ローカルで完結する UI 状態
//   - アコーディオンの開閉
//   - タブのインデックス
//   - フォームの一時的な入力値
final isOpen = useState(false);
final selectedTab = useState(0);

// ✅ Riverpod Notifier: 複数 Widget から参照・変更される状態
//   - ユーザー情報
//   - カート内容
//   - 認証状態
final user = ref.watch(userNotifierProvider);
final cart = ref.watch(cartProvider);
```

### HookConsumerWidget のテスト

```dart
// hooks のテストは通常の Widget テストと同じ書き方でOK
testWidgets('カウントアップボタンが動作する', (tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: ExampleWidget()),
    ),
  );

  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.text('Increment'));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```

---

## 共通アンチパターン

| アンチパターン | 問題 | 修正方法 |
|-------------|------|---------|
| UI で状態管理オブジェクトを直接生成 | テスト不可 | DI で注入 |
| BLoC 内で BuildContext を使用 | UI に依存 | BlocListener で処理 |
| Notifier 内で ref.read を build で使用 | 依存追跡できない | ref.watch を使う |
| グローバル変数で状態管理 | 予測不可能 | Provider/Notifier を使う |
| 状態を複数箇所で独立して管理 | 不整合 | Single Source of Truth |
| サーバー状態を useState で管理 | キャッシュなし・重複リクエスト | Riverpod Notifier を使う |
| hooks を StatefulWidget の中で使う | hooks は StatelessWidget 系のみ | HookConsumerWidget に変更 |

---

## チェックリスト

- [ ] State は immutable（copyWith で更新）
- [ ] エラー状態が定義されている
- [ ] ローディング状態が定義されている
- [ ] Provider/BLoC は UI に依存していない
- [ ] コントローラー類は useXxx hooks で自動 dispose している
- [ ] Widget ローカル状態は useState、グローバル状態は Riverpod で管理している
- [ ] テストでモックに差し替えられる
