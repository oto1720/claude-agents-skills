# Dart Style Rules

## 命名規則（Dart 公式）

```dart
// クラス・型・Enum: UpperCamelCase
class UserRepository {}
enum UserRole { admin, member }
typedef JsonMap = Map<String, dynamic>;

// 変数・関数・パラメータ: lowerCamelCase
var userName = 'Alice';
void getUserById(String id) {}

// 定数: lowerCamelCase（Dart では UPPER_SNAKE_CASE は非推奨）
const maxRetryCount = 3;
const apiBaseUrl = 'https://api.example.com';

// プライベート: _ プレフィックス
String _internalState = '';
void _processData() {}

// ファイル名: snake_case
// user_repository.dart, home_screen.dart
```

## 型アノテーション

```dart
// ✅ 戻り値の型は常に明示
String getUserName() => _name;
Future<User> fetchUser(String id) async { ... }

// ✅ ローカル変数は型推論を活用
final user = await repository.getUser(id); // User 型が推論される
var count = 0;

// ❌ dynamic は原則禁止
dynamic processData(dynamic input) { ... } // 型安全性を失う

// ✅ 代わりに型パラメータか具体的な型を使う
T processData<T>(T input) { ... }
```

## Null Safety

```dart
// ✅ nullable は必要最小限
String? nullableName; // 本当に null になる場合のみ

// ❌ ! (null assertion) の多用は禁止
final name = user!.name; // クラッシュリスク

// ✅ 代わりに null チェック・?? を使う
final name = user?.name ?? 'Unknown';

// ✅ late は初期化が保証されている場合のみ
late final _controller = TextEditingController(); // initState で確実に初期化

// ❌ late を null 回避のために使わない
late String? _name; // ❌ late + nullable は矛盾
```

## Dart イディオム

```dart
// ✅ cascade notation
final paint = Paint()
  ..color = Colors.blue
  ..strokeWidth = 2.0
  ..style = PaintingStyle.stroke;

// ✅ spread operator
final allItems = [...listA, ...listB, newItem];

// ✅ collection if / for
final children = [
  const Header(),
  if (isLoggedIn) const UserProfile(),
  for (final item in items) ItemWidget(item: item),
];

// ✅ pattern matching (Dart 3.0+)
switch (state) {
  case UserLoaded(:final user) => UserCard(user: user),
  case UserError(:final message) => ErrorView(message: message),
  case UserLoading() => const CircularProgressIndicator(),
  case UserInitial() => const SizedBox.shrink(),
}
```

## Sealed Classes（Dart 3.0+）

```dart
// ✅ 状態・結果の網羅的な表現に sealed class を使う
sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final User user;
}

final class AuthFailure extends AuthResult {
  const AuthFailure(this.message);
  final String message;
}

// switch で網羅性チェックが効く
final message = switch (result) {
  AuthSuccess(:final user) => 'Welcome, ${user.name}',
  AuthFailure(:final message) => 'Error: $message',
};
```

## 禁止事項

| 禁止 | 理由 | 代替 |
|------|------|------|
| `dynamic` の多用 | 型安全性を失う | 具体的な型 / ジェネリクス |
| `!` の多用 | クラッシュリスク | `?.` / `??` / null チェック |
| `print()` | 本番でもログが出る | `debugPrint()` / logger |
| グローバル変数 | テスト不可・予測不可 | DI / Provider |
| `rethrow` なしの catch | デバッグ困難 | ログ後 rethrow |
