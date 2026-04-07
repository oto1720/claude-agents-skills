---
name: flutter-widget-design
description: Flutter Widget の設計・分割・composition パターンに関するベストプラクティス
---

# Flutter Widget Design

## いつ使うか

- Widget を設計・分割するとき
- 再利用可能な Widget を作るとき
- Widget のネストが深くなってきたとき
- StatelessWidget と StatefulWidget の選択に迷ったとき

---

## コアコンセプト

### 1. Widget 分割の原則

**分割のトリガー**:
- build() が50行を超えたら分割を検討
- 同じ Widget が2箇所以上で使われたら抽出
- テストしたい単位で分割

```dart
// ❌ 巨大な build()
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          // 50行のヘッダー
          // 100行のリスト
          // 30行のフッター
        ],
      ),
    );
  }
}

// ✅ 責任ごとに分割
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: const Column(
        children: [
          HomeHeader(),
          Expanded(child: HomeList()),
          HomeFooter(),
        ],
      ),
    );
  }
}
```

### 2. const Widget の徹底

```dart
// ✅ 変更されない Widget は必ず const
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: NetworkImage(imageUrl),
      radius: 24,
    );
  }
}

// 使用時も const
const UserAvatar(imageUrl: 'https://example.com/avatar.jpg')
```

### 3. State Hoisting（状態の引き上げ）

```dart
// ❌ 内部で状態を持つ（テスト・再利用が困難）
class SearchField extends StatefulWidget {
  @override
  State<SearchField> createState() => _SearchFieldState();
}
class _SearchFieldState extends State<SearchField> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
    );
  }
}

// ✅ 状態を親から受け取る（テスタブル・再利用可能）
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
}
```

### 4. Widget の種類と使い分け

```dart
// StatelessWidget: 外部から渡されたデータのみ表示
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) => Card(
    child: Text(user.name),
  );
}

// ConsumerWidget (Riverpod): グローバル状態を読む
class UserProfile extends ConsumerWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      data: (u) => UserCard(user: u),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => ErrorView(message: e.toString()),
    );
  }
}

// HookConsumerWidget (hooks_riverpod): ローカル状態 + グローバル状態
// → StatefulWidget の代替として最も推奨
class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // コントローラー類が自動 dispose される
    final controller = useTextEditingController();
    final isLoading = useState(false);
    final results = ref.watch(searchResultsProvider);

    return TextField(controller: controller);
  }
}

// StatefulWidget: hooks が使えない場面（外部パッケージとの統合など）
// → 原則として HookConsumerWidget で代替できないか先に検討する
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({super.key, required this.count});
  final int count;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}
```

#### 選択フロー

```
Widget を作るとき
  ↓
グローバル状態(Riverpod)が必要？
  YES → ローカル状態(useState)も必要？
           YES → HookConsumerWidget  ← 最も多いケース
           NO  → ConsumerWidget
  NO  → ローカル状態(useState)が必要？
           YES → HookWidget
           NO  → StatelessWidget（const 推奨）

※ StatefulWidget は原則として最後の手段
```

---

## デザインパターン

### Compound Widget パターン

```dart
// 関連する Widget をグループ化
class UserListTile extends StatelessWidget {
  const UserListTile({super.key, required this.user, this.onTap});

  final User user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(imageUrl: user.avatarUrl),
      title: UserName(name: user.name),
      subtitle: UserRole(role: user.role),
      onTap: onTap,
    );
  }
}
```

### Slot パターン（Scaffold 風）

```dart
class PageTemplate extends StatelessWidget {
  const PageTemplate({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.bottomBar,
  });

  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
    );
  }
}
```

---

## アンチパターン

| アンチパターン | 問題 | 修正方法 |
|-------------|------|---------|
| God Widget（1000行の build） | 読めない・テスト不可 | 責任ごとに分割 |
| BuildContext を async で使用 | クラッシュ | `mounted` チェック後に使用 |
| Widget内でビジネスロジック | テスト不可 | Notifier/UseCase に移動 |
| 毎フレーム重い計算 | jank | build() 外 or Notifier に移動 |
| 深すぎるネスト | 読みにくい | Widget に抽出 |

---

## チェックリスト

- [ ] 変更されない Widget に `const` を付けた
- [ ] build() が50行以下
- [ ] ビジネスロジックは Widget 内にない
- [ ] 状態は適切な場所で管理されている
- [ ] async の後に `mounted` チェックがある
- [ ] Widget テストが書ける粒度になっている
