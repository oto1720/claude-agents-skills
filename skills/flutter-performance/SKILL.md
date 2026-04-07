---
name: flutter-performance
description: Flutter アプリのパフォーマンス最適化（const・rebuild削減・メモリ・Image）のベストプラクティス
---

# Flutter Performance

## いつ使うか

- アプリの動作が重いとき（jank・FPS 低下）
- Widget の rebuild 回数を減らしたいとき
- const 最適化を行うとき
- メモリ使用量を削減したいとき

---

## パフォーマンス計測ツール

```bash
# Profile モードで実行（Release に近い計測）
flutter run --profile

# DevTools で確認
# - Performance タブ: UI/Raster スレッド
# - Widget Inspector: rebuild カウント
# - Memory タブ: ヒープ使用量
```

---

## 最適化カテゴリ

### 1. const Widget の徹底

Flutter の最重要最適化。const Widget はビルド時に作成され、再利用される。

```dart
// ❌ 毎フレーム新しいインスタンス生成
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)

// ✅ const: 1回だけ生成・キャッシュ
const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
)
```

**検出コマンド**:
```bash
# const を付けられるのに付いていない箇所
flutter analyze 2>&1 | grep "prefer_const"

# analysis_options.yaml で警告を有効化
# rules:
#   prefer_const_constructors: true
#   prefer_const_literals_to_create_immutables: true
```

### 2. StatelessWidget と ConsumerWidget の正しい選択

```dart
// ❌ State が不要なのに StatefulWidget
class UserAvatar extends StatefulWidget {
  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

// ✅ StatelessWidget で十分
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.url});
  final String url;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    backgroundImage: NetworkImage(url),
  );
}
```

### 3. build() 内の重い処理を排除

```dart
// ❌ build 毎に重い計算
class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // rebuild のたびに全件フィルタリング
    final activeUsers = users.where((u) => u.isActive).toList();
    return ListView.builder(itemCount: activeUsers.length, ...);
  }
}

// ✅ Notifier / Provider で計算・キャッシュ
@riverpod
List<User> activeUsers(ActiveUsersRef ref) {
  final users = ref.watch(usersProvider);
  return users.where((u) => u.isActive).toList();
}

class UserList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeUsers = ref.watch(activeUsersProvider);
    return ListView.builder(itemCount: activeUsers.length, ...);
  }
}
```

### 4. ListView の最適化

```dart
// ❌ 全アイテムを一度に生成
ListView(children: items.map((i) => ItemWidget(i)).toList())

// ✅ 必要な分だけ生成（Lazy Loading）
ListView.builder(
  itemCount: items.length,
  itemBuilder: (_, index) => ItemWidget(items[index]),
)

// ✅ 固定高さなら itemExtent で更に最適化
ListView.builder(
  itemCount: items.length,
  itemExtent: 72.0,  // 全アイテムが同じ高さの場合
  itemBuilder: (_, index) => ItemWidget(items[index]),
)

// ✅ 分離線付きリスト
ListView.separated(
  itemCount: items.length,
  separatorBuilder: (_, __) => const Divider(),
  itemBuilder: (_, index) => ItemWidget(items[index]),
)
```

### 5. RepaintBoundary で再描画範囲を限定

```dart
// アニメーションが他の Widget に影響しないように
RepaintBoundary(
  child: AnimatedWidget(),
)

// スクロールリスト内の複雑な Widget
ListView.builder(
  itemBuilder: (_, index) => RepaintBoundary(
    child: ComplexCard(item: items[index]),
  ),
)
```

### 6. Image の最適化

```dart
// ✅ cacheWidth/cacheHeight でメモリ節約
Image.network(
  url,
  cacheWidth: 300,     // 表示サイズに合わせる
  cacheHeight: 300,
  fit: BoxFit.cover,
)

// ✅ CachedNetworkImage パッケージを使用（ディスクキャッシュ）
CachedNetworkImage(
  imageUrl: url,
  placeholder: (_, __) => const ShimmerPlaceholder(),
  errorWidget: (_, __, ___) => const Icon(Icons.error),
)

// ✅ precacheImage で事前読み込み
@override
void initState() {
  super.initState();
  precacheImage(NetworkImage(imageUrl), context);
}
```

### 7. Riverpod select で部分 rebuild

```dart
// ❌ State 全体を監視 → 関係ない変更でも rebuild
final user = ref.watch(userProvider);
return Text(user.name); // email が変わっても rebuild される

// ✅ 必要なフィールドのみ監視
final name = ref.watch(userProvider.select((u) => u.name));
return Text(name); // name が変わったときのみ rebuild
```

### 8. async/await と mounted チェック

```dart
// ❌ dispose 後に setState → エラー
void _loadData() async {
  final data = await fetchData();
  setState(() => _data = data);  // dispose 済みかもしれない
}

// ✅ mounted チェック
void _loadData() async {
  final data = await fetchData();
  if (mounted) {
    setState(() => _data = data);
  }
}
```

---

## パフォーマンスチェックリスト

| 項目 | チェック |
|------|---------|
| const Widget が使われている | [ ] |
| build() 内で重い計算をしていない | [ ] |
| ListView.builder を使っている | [ ] |
| 不要な StatefulWidget がない | [ ] |
| Image に cacheWidth/cacheHeight がある | [ ] |
| Riverpod で select を使っている | [ ] |
| Profile モードで60FPS 維持 | [ ] |

---

## よくある jank の原因と対処

| 原因 | 症状 | 対処 |
|------|------|------|
| build() 内の重い処理 | スクロール時に詰まる | Isolate / compute に移動 |
| 大きな画像をそのまま表示 | 初回表示が遅い | cacheWidth/cacheHeight |
| 非同期処理を UI スレッドでブロック | フリーズ | compute / Isolate |
| 過剰な setState | 全体が再描画 | 最小粒度で setState |
| 透明度アニメーション | GPU 負荷 | AnimatedOpacity より FadeTransition |
