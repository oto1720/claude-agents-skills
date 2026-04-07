---
name: flutter-architecture
description: Flutter プロジェクトの規模・チーム・要件に応じたアーキテクチャ選択フレームワークと実装パターン
---

# Flutter Architecture

## いつ使うか

- 新規 Flutter プロジェクトのアーキテクチャを決めるとき
- 既存プロジェクトのリファクタリング方針を決めるとき
- 「このアーキテクチャで本当にいいか？」を確認したいとき
- チームでアーキテクチャの議論をするとき

---

## Step 1: プロジェクトを診断する

まず以下の質問に答えて、適切なアーキテクチャを特定する。

```
Q1. プロジェクトの規模は？
  a) 個人・プロト・社内ツール（画面10枚以下）
  b) 中規模アプリ（画面10〜30枚、チーム2〜5人）
  c) 大規模アプリ（画面30枚以上、チーム5人以上、長期運用）

Q2. バックエンドとの接続は？
  a) Firebase / Supabase などの BaaS 中心
  b) REST API / GraphQL
  c) オフライン優先（ローカルDB + 同期）

Q3. テストの要求レベルは？
  a) 主要フローのみ
  b) Unit Test 80%以上
  c) フルカバレッジ（Unit + Widget + Integration）

Q4. 既存コードはあるか？
  a) 完全新規
  b) 既存コードあり（段階的に移行）
```

---

## アーキテクチャ選択マトリクス

| Q1 規模 | Q2 バックエンド | 推奨アーキテクチャ |
|--------|--------------|-----------------|
| a) 小規模 | any | **Tier 1: Simple MVVM** |
| b) 中規模 | a) BaaS | **Tier 2: Feature-first + Repository** |
| b) 中規模 | b) REST | **Tier 2: Feature-first + Repository** |
| c) 大規模 | any | **Tier 3: Clean Architecture** |
| any | c) オフライン優先 | **Tier 3: Clean Architecture** |

---

## Tier 1: Simple MVVM（小規模・プロト）

**いつ使う**: 個人アプリ・社内ツール・プロト・ハッカソン

**特徴**: UseCase層なし・Repository Interface なし・シンプルさ優先

```
lib/
├── features/
│   └── user/
│       ├── user_screen.dart        # UI
│       ├── user_notifier.dart      # 状態管理（Riverpod Notifier）
│       └── user_repository.dart   # データアクセス（クラスのみ、Interface なし）
├── core/
│   ├── api_client.dart
│   └── router.dart
└── main.dart
```

### 実装例

```dart
// user_repository.dart: Interface なし・シンプルなクラス
class UserRepository {
  const UserRepository(this._client);
  final ApiClient _client;

  Future<User> getUser(String id) async {
    final res = await _client.get('/users/$id');
    return User.fromJson(res.data);
  }
}

// user_notifier.dart: Repository を直接 ref.watch
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String id) {
    final repo = ref.watch(userRepositoryProvider);
    return repo.getUser(id);
  }
}

// user_screen.dart
class UserScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userNotifierProvider(userId));
    return userAsync.when(
      data: (u) => Text(u.name),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Tier 1 のトレードオフ

| メリット | デメリット |
|---------|---------|
| 学習コスト低・実装が速い | テストで Repository をモックしにくい |
| ボイラープレートが少ない | 規模が大きくなるとリファクタが必要 |
| プロトから本番移行が容易 | チームで統一しにくい |

---

## Tier 2: Feature-first + Repository（中規模）

**いつ使う**: チーム2〜5人・中規模アプリ・API 中心・テスト重視

**特徴**: Repository Interface あり・UseCase は必要なときだけ追加

```
lib/
├── features/
│   └── user/
│       ├── data/
│       │   ├── user_api.dart            # API アクセス
│       │   └── user_repository_impl.dart
│       ├── domain/
│       │   ├── user.dart                # Entity
│       │   └── user_repository.dart     # Interface
│       └── presentation/
│           ├── user_screen.dart
│           ├── user_notifier.dart
│           └── widgets/
├── core/
│   ├── network/
│   ├── router/
│   └── theme/
└── main.dart
```

### 実装例

```dart
// domain/user_repository.dart: Interface のみ定義
abstract interface class UserRepository {
  Future<User> getUser(String id);
  Future<void> updateUser(User user);
}

// data/user_repository_impl.dart: 実装
class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._api);
  final UserApi _api;

  @override
  Future<User> getUser(String id) async {
    final dto = await _api.getUser(id);
    return User(id: dto.id, name: dto.name);  // DTO → Entity
  }
}

// Riverpod で DI（get_it 不要・シンプル）
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepositoryImpl(ref.watch(userApiProvider));
}

@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String id) {
    return ref.watch(userRepositoryProvider).getUser(id);
  }
}
```

### UseCase を追加するタイミング

```dart
// ❌ UseCase を全部に作る必要はない（Notifier で直接 Repository を使ってOK）
@riverpod
class UserNotifier extends _$UserNotifier {
  @override
  Future<User> build(String id) =>
      ref.watch(userRepositoryProvider).getUser(id);  // Repository 直呼びでOK
}

// ✅ UseCase を作るのは以下のケースのみ
// - 複数の Repository をまたぐビジネスロジック
// - 同じロジックを複数の Notifier で使う
// - 複雑な変換・バリデーションが含まれる
class PlaceOrderUseCase {
  const PlaceOrderUseCase(this._orderRepo, this._stockRepo, this._notifyRepo);

  Future<Order> call(Cart cart) async {
    await _stockRepo.decreaseStock(cart.items);    // 在庫を減らす
    final order = await _orderRepo.create(cart);   // 注文を作成
    await _notifyRepo.sendConfirmation(order);     // 通知を送る
    return order;
  }
}
```

### Tier 2 のトレードオフ

| メリット | デメリット |
|---------|---------|
| テストで Repository をモック可能 | Tier 1 より構造が複雑 |
| チームで統一しやすい | Interface の定義が必要 |
| 大規模化への移行が容易 | 慣れるまで学習コストがある |

---

## Tier 3: Clean Architecture（大規模・長期運用）

**いつ使う**: チーム5人以上・30画面以上・複数プラットフォーム・長期運用

**特徴**: Domain 層が外部依存ゼロ・UseCase が全ビジネスロジックを持つ・フルテスト

```
lib/
├── features/
│   └── user/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── user_remote_datasource.dart
│       │   │   └── user_local_datasource.dart  # キャッシュ
│       │   ├── models/
│       │   │   └── user_dto.dart               # JSON モデル
│       │   └── repositories/
│       │       └── user_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── user.dart                   # 純粋 Dart
│       │   ├── repositories/
│       │   │   └── user_repository.dart        # Interface
│       │   └── usecases/
│       │       ├── get_user.dart
│       │       └── update_user_profile.dart
│       └── presentation/
│           ├── pages/
│           ├── widgets/
│           └── providers/
├── core/
│   ├── di/          # get_it + injectable
│   ├── error/       # Failure / Exception 階層
│   ├── network/
│   ├── router/
│   └── utils/
└── main.dart
```

### 依存ルール（絶対に守る）

```
presentation  →  domain  ←  data
                   ↑
              外部依存なし
              (純粋 Dart のみ)
```

```dart
// domain/entities/user.dart: Flutter すら import しない
class User {
  const User({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
  User copyWith({String? id, String? name, String? email}) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
  );
}

// ❌ domain に絶対に入れてはいけない import
import 'package:flutter/material.dart';  // ❌
import 'package:dio/dio.dart';           // ❌
import 'package:drift/drift.dart';       // ❌
```

### Tier 3 のトレードオフ

| メリット | デメリット |
|---------|---------|
| 最高のテスタビリティ | 初期の実装量が多い |
| レイヤー違反を構造で防止 | 学習コストが高い |
| 複数プラットフォーム対応しやすい | 小さい変更でも複数ファイル変更が必要 |
| チームが大きくても衝突しにくい | Over-engineering になりやすい |

---

## 既存コードへの段階的移行

既存プロジェクトにアーキテクチャを導入するときは**段階的に**行う。

```
フェーズ1（すぐできる）:
  - Riverpod / hooks_riverpod を導入
  - StatefulWidget を HookConsumerWidget に置き換え
  - ビジネスロジックを Widget から Notifier に移動

フェーズ2（Feature ごとに）:
  - API アクセスを Repository クラスに集約
  - 新しい Feature は Tier 2 で実装
  - 既存機能は触るたびに Tier 2 に移行

フェーズ3（必要になってから）:
  - UseCase を複雑なロジックにのみ追加
  - Domain Interface を追加（テストが通ってから）
  - Tier 3 は本当に必要になった機能のみ
```

---

## BaaS（Firebase / Supabase）を使う場合

```dart
// Repository が BaaS を直接使う → Domain は BaaS を知らない

// ❌ Presentation が Firebase を直接使う
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = FirebaseFirestore.instance.collection('users').snapshots();
    ...
  }
}

// ✅ Repository が Firebase を隠蔽する
class UserRepositoryImpl implements UserRepository {
  final _firestore = FirebaseFirestore.instance;

  @override
  Stream<User> watchUser(String id) {
    return _firestore
        .collection('users')
        .doc(id)
        .snapshots()
        .map((snap) => User.fromJson(snap.data()!));  // DTO → Entity
  }
}
```

BaaS を使う場合は Tier 2 で十分なことが多い。
UseCase が薄くなるなら Repository を直接 Notifier から呼ぶ。

---

## アンチパターン（どのTierでも共通）

| アンチパターン | 問題 | 修正方法 |
|-------------|------|---------|
| Widget で API を直接呼ぶ | テスト不可・責任混在 | Notifier → Repository に移動 |
| Notifier がビジネスロジックを持ちすぎる | テストが複雑 | UseCase に切り出す |
| プロジェクト全体に同じ Tier を強制 | 過剰 or 不足 | Feature ごとに適切な Tier を選ぶ |
| 「いつか使うから」で Tier 3 を採用 | Over-engineering | 今必要な Tier から始める |
| Entity に fromJson を書く | Domain が外部形式に依存 | DTO / Model クラスに移動 |

---

## チェックリスト

### 診断

- [ ] プロジェクトの規模・チームサイズを確認した
- [ ] バックエンドの種類を確認した（BaaS / REST / オフライン）
- [ ] テスト要求レベルを確認した
- [ ] 現在の技術スタック・チームの習熟度を確認した

### 決定

- [ ] 上記を踏まえて Tier 1 / 2 / 3 を選んだ
- [ ] 採用しないレイヤー（例: UseCase なし）を明示した
- [ ] 段階的移行の場合はフェーズを決めた

### 実装

- [ ] 依存の方向が正しい（presentation → domain ← data）
- [ ] 選んだ Tier のボイラープレートを超えていない
- [ ] 各レイヤーが独立してテスト可能
- [ ] Entity は immutable + copyWith
