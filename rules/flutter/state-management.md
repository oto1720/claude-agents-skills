# Flutter State Management Rules

## hooks_riverpod ルール

### Widget の基本形は HookConsumerWidget

```dart
// ✅ HookConsumerWidget: グローバル状態 + ローカル状態を両方扱える
class MyScreen extends HookConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ローカル状態: useState（サーバーデータ以外の UI 状態）
    final isExpanded = useState(false);

    // コントローラー: use系 hooks で自動 dispose
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final animController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // グローバル状態: ref.watch（通常の Riverpod と同じ）
    final user = ref.watch(userNotifierProvider);

    // サイドエフェクト: useEffect（initState/dispose 相当）
    useEffect(() {
      controller.addListener(() {
        // テキスト変更を監視
      });
      return controller.removeListener; // クリーンアップ
    }, []);

    return ...;
  }
}
```

### hooks のルール

```dart
// ✅ hooks は必ず build() の最上位レベルで呼ぶ
Widget build(BuildContext context, WidgetRef ref) {
  final count = useState(0);      // OK: 最上位
  final name = useState('');      // OK: 最上位

  return Column(children: [
    // ❌ 条件分岐の中で hooks を呼んではいけない
    // if (someCondition) useState(0),  // NG!
    // ❌ ループの中で hooks を呼んではいけない
    // for (final _ in items) useState(0),  // NG!
  ]);
}

// ✅ useState の値は .value でアクセス・更新
final counter = useState(0);
Text('${counter.value}')           // 読み取り
counter.value++;                   // 更新（rebuild トリガー）
counter.value = 10;                // 代入
```

### useState vs Riverpod の境界

```dart
// useState を使う（Widget ローカルの UI 状態）
final isLoading = useState(false);     // ボタンのローカルローディング
final isExpanded = useState(false);    // アコーディオン開閉
final selectedIndex = useState(0);    // タブ選択

// Riverpod を使う（アプリ全体・複数 Widget で共有）
final user = ref.watch(userProvider);        // ユーザー情報
final cart = ref.watch(cartProvider);        // カート
final authState = ref.watch(authProvider);   // 認証状態
```

---

## Riverpod ルール

### Provider の設計

```dart
// ✅ @riverpod アノテーション（コード生成推奨）
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String userId) async {
    // ref.watch で依存を宣言（自動的にキャンセル・再実行される）
    final repository = ref.watch(userRepositoryProvider);
    return repository.getUser(userId);
  }
}

// ✅ 純粋なデータ取得は関数形式
@riverpod
Future<List<User>> users(UsersRef ref) {
  return ref.watch(userRepositoryProvider).getUsers();
}

// ❌ ProviderScope の外で ref を使う
// ❌ build() 外で ref.watch を使う（ref.read を使う）
```

### ref.watch vs ref.read vs ref.listen

```dart
// ref.watch: build() 内 → 変更を監視して rebuild
final user = ref.watch(userProvider);

// ref.read: イベントハンドラ内 → 一度だけ読む（監視しない）
onPressed: () => ref.read(counterProvider.notifier).increment(),

// ref.listen: 変更に反応してサイドエフェクト（ナビゲーション・SnackBar）
ref.listen(authStateProvider, (previous, next) {
  if (next is Unauthenticated) {
    context.go('/login');
  }
});
```

### 状態の更新

```dart
// ✅ Notifier 内での状態更新
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    // state は immutable に更新
    state = [...state, item];
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
  }
}

// ❌ state を直接変更（immutability 違反）
void addItem(CartItem item) {
  state.add(item); // ❌ List を直接変更
}
```

### AsyncValue の扱い

```dart
// ✅ when で全状態を網羅的に処理
userAsync.when(
  data: (user) => UserCard(user: user),
  loading: () => const CircularProgressIndicator(),
  error: (e, stack) => ErrorView(
    message: e.toString(),
    onRetry: () => ref.invalidate(userProvider),
  ),
);

// ✅ maybeWhen でデータのみ処理（他は null）
userAsync.maybeWhen(
  data: (user) => Text(user.name),
  orElse: () => null,
);

// ✅ value / error / isLoading プロパティでチェック
if (userAsync.isLoading) return const Spinner();
if (userAsync.hasError) return ErrorView(...);
final user = userAsync.value!; // isLoading/hasError チェック後は安全
```

## 禁止事項

| 禁止 | 理由 | 代替 |
|------|------|------|
| `state` を直接変更 | Riverpod が変更を検知できない | `state = state.copyWith(...)` |
| `build()` 内で `ref.read` | 変更を追跡できない | `ref.watch` |
| イベントハンドラで `ref.watch` | 不要な rebuild | `ref.read` |
| Provider を UI コンポーネント内で作成 | テスト不可 | `ProviderScope` / DI |
| `autoDispose` なしで使い捨て Provider | メモリリーク | `@riverpod`（デフォルト autoDispose） |
