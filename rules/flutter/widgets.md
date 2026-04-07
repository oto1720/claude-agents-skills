# Flutter Widget Rules

## const の徹底

```dart
// 変更されない Widget には必ず const を付ける
// analysis_options.yaml で prefer_const_constructors: true を設定すること

// ✅
const Text('Hello')
const Icon(Icons.star)
const SizedBox(height: 16)
const Padding(padding: EdgeInsets.all(8), child: Text('Hi'))

// ❌
Text('Hello')         // const なし → rebuild のたびに新しいインスタンス
Icon(Icons.star)      // const なし
```

## build() 内の禁止事項

```dart
// ❌ build() 内で重い処理
Widget build(BuildContext context) {
  final filtered = hugeList.where((e) => e.isActive).toList(); // 毎回実行
  return ListView.builder(...);
}

// ✅ Provider/Notifier で計算
@riverpod
List<Item> activeItems(ActiveItemsRef ref) {
  return ref.watch(itemsProvider).where((e) => e.isActive).toList();
}

// ❌ build() 内でオブジェクト生成（インスタンス比較が壊れる）
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () => viewModel.submit(), // 毎回新しい lambda
    child: const Text('Submit'),
  );
}

// ✅ メソッド参照か remember を使う
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: viewModel.submit, // メソッド参照（同じインスタンス）
    child: const Text('Submit'),
  );
}
```

## Widget の粒度

```dart
// build() が 50行を超えたら分割のサイン
// ❌ 大きな build()
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 200行...
    );
  }
}

// ✅ 責任ごとに分割
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: const Column(children: [
        HomeHeader(),
        Expanded(child: HomeList()),
      ]),
      floatingActionButton: const HomeActionButton(),
    );
  }
}
```

## StatefulWidget の使用制限

```dart
// StatefulWidget を使って良いケース:
// - AnimationController が必要
// - FocusNode / TextEditingController などのコントローラーが必要
// - initState / dispose が必要
// - ページネーションなどの純粋な UI 状態

// ❌ これは StatelessWidget + ConsumerWidget で書ける
class UserScreen extends StatefulWidget {
  @override
  State<UserScreen> createState() => _UserScreenState();
}
class _UserScreenState extends State<UserScreen> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await repository.getUser();
    setState(() => _user = user);
  }
  ...
}

// ✅ Riverpod Notifier に移動
class UserScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider);
    return userAsync.when(...);
  }
}
```

## Keys の使い方

```dart
// Key が必要なケース:
// 1. リスト内の Widget の順序変更
// 2. 同じ型の Widget を複数使う場合の識別
// 3. テスト時の Widget 特定

// ✅ ValueKey: データのIDを使う
ListView.builder(
  itemBuilder: (_, i) => UserCard(
    key: ValueKey(users[i].id), // ユーザーIDをキーに
    user: users[i],
  ),
)

// ✅ GlobalKey: 外部からのアクセス
final _formKey = GlobalKey<FormState>();
Form(key: _formKey, child: ...)

// ❌ UniqueKey: rebuild のたびに新しいキー = Widget が再生成される
// (意図的に再生成したい場合のみ使用)
```

## Overlay / Dialog / SnackBar

```dart
// ✅ go_router を使った画面遷移
context.go('/user/$id');

// ✅ SnackBar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('保存しました')),
);

// ✅ Dialog
showDialog(
  context: context,
  builder: (_) => const AlertDialog(
    title: Text('確認'),
    content: Text('削除しますか？'),
  ),
);

// ❌ Navigator.of(context) を async の後で使う（mounted チェック必須）
```
