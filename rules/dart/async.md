# Dart Async Rules

## Future / async-await

```dart
// ✅ async/await を使う（then チェーンより読みやすい）
Future<User> getUser(String id) async {
  final response = await apiClient.get('/users/$id');
  return User.fromJson(response.data);
}

// ❌ then チェーンは避ける
Future<User> getUser(String id) {
  return apiClient.get('/users/$id').then((response) {
    return User.fromJson(response.data);
  });
}

// ✅ エラーハンドリングは try/catch で
Future<User> getUser(String id) async {
  try {
    return await apiClient.get('/users/$id').then(User.fromJson);
  } on DioException catch (e) {
    throw NetworkException(e.message);
  }
}
```

## Future.wait で並列実行

```dart
// ✅ 独立したリクエストは並列実行
final (user, posts) = await (
  userRepository.getUser(id),
  postRepository.getPosts(userId: id),
).wait;

// ❌ 順次実行は遅い
final user = await userRepository.getUser(id);
final posts = await postRepository.getPosts(userId: id);
```

## Stream

```dart
// ✅ StreamController は必ず close する
class DataService {
  final _controller = StreamController<Data>.broadcast();
  Stream<Data> get stream => _controller.stream;

  void dispose() {
    _controller.close(); // 必須
  }
}

// ✅ StreamSubscription は必ず cancel する
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription<Data>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = dataService.stream.listen(_onData);
  }

  @override
  void dispose() {
    _subscription?.cancel(); // 必須
    super.dispose();
  }
}
```

## compute / Isolate（重い処理）

```dart
// ✅ JSON の大量パース、画像処理など重い処理は Isolate に移す
Future<List<User>> parseUsers(String json) {
  return compute(_parseUsersInBackground, json);
}

List<User> _parseUsersInBackground(String json) {
  // UI スレッドをブロックしない
  final list = jsonDecode(json) as List;
  return list.map((e) => User.fromJson(e)).toList();
}
```

## mounted チェック（StatefulWidget）

```dart
// ✅ async 後の BuildContext 使用前に mounted チェック
Future<void> _submit() async {
  final result = await repository.save(_data);
  if (!mounted) return; // Widget が破棄されていたら何もしない
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result.message)),
  );
}
```

## 禁止事項

| 禁止 | 理由 | 代替 |
|------|------|------|
| UI スレッドでの重い処理 | jank 発生 | `compute` / `Isolate` |
| `StreamController` の close 忘れ | メモリリーク | dispose で close |
| async 後の BuildContext 無検証使用 | クラッシュ | `mounted` チェック |
| `Completer` の多用 | 複雑化 | async/await |
| `unawaited()` の不用意な使用 | エラー無視 | 明示的な例外処理 |
