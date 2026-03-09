---
name: nextjs-ui-standards
description: Next.js UIコード規範・規約の適用スキル。Next.jsのコンポーネント、ページ、レイアウト、フォーム、データテーブル、モーダルなどUI要素の作成・レビュー・生成時に使用する。「Next.jsのコンポーネントを作って」「フォームを実装したい」「このページをどう構成すべきか」「Server Componentを書いて」「モーダルを追加して」「データテーブルを作って」「Next.jsのUIパターンを教えて」などのリクエストでトリガーする。ファイル構成、TypeScript規約、Tailwindパターン、shadcn/uiに関する質問でも使用すること。
---

# Next.js UI コード規範

あなたはエキスパートのNext.jsエンジニアです。UIコードを生成・レビューする際は、このスキルの規約を一貫して適用してください。

## 基本原則

**App Router**（Next.js 13+）を使って本番品質のコードを書く。Server Componentを優先する。サーバーとクライアントのコード境界を明示的かつ最小限に保つ。TypeScriptをデフォルトとする。

---

## 1. ファイル・フォルダ構成

```
src/
├── app/                    # App Routerのページとレイアウト
│   ├── (auth)/             # ルートグループ：認証ページ
│   ├── (dashboard)/        # ルートグループ：ダッシュボードページ
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── api/                # APIルート（Route Handlers）
│   ├── globals.css
│   └── layout.tsx          # ルートレイアウト
├── components/
│   ├── ui/                 # プリミティブUIコンポーネント（shadcn/ui形式）
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   └── ...
│   ├── forms/              # フォームコンポーネント
│   ├── layouts/            # レイアウト用コンポーネント
│   └── [feature]/          # 機能別コンポーネント
├── lib/
│   ├── utils.ts            # ユーティリティ関数（cn等）
│   └── validations/        # Zodスキーマ
├── hooks/                  # カスタムReactフック（クライアント）
├── types/                  # 共有TypeScript型定義
└── server/                 # サーバー専用コード（DB、認証等）
```

**ルール:**
- ディレクトリは `kebab-case`、コンポーネントファイルは `PascalCase`
- テストファイルはコンポーネントと同じディレクトリに置く（`button.test.tsx`）
- `server/` は必ずサーバー専用にする（`server-only` パッケージでガード）

---

## 2. Server Component vs Client Component

### デフォルト: Server Component

```tsx
// app/(dashboard)/users/page.tsx
// "use client" なし → Server Component

import { UserTable } from "@/components/users/user-table";
import { getUsers } from "@/server/queries/users";

export default async function UsersPage() {
  const users = await getUsers();
  return (
    <main className="container py-8">
      <h1 className="text-2xl font-bold mb-6">ユーザー一覧</h1>
      <UserTable users={users} />
    </main>
  );
}
```

### Client Component — 必要な場合のみ

以下が必要な場合のみ `"use client"` を追加する:
- `useState`、`useEffect`、`useReducer`
- ブラウザAPI（`window`、`localStorage`）
- Server Actionsで対応できないイベントハンドラ
- クライアント専用のサードパーティライブラリ

```tsx
// components/users/user-search.tsx
"use client";

import { useState } from "react";
import { Input } from "@/components/ui/input";

interface UserSearchProps {
  onSearch: (query: string) => void;
}

export function UserSearch({ onSearch }: UserSearchProps) {
  const [query, setQuery] = useState("");

  return (
    <Input
      value={query}
      onChange={(e) => {
        setQuery(e.target.value);
        onSearch(e.target.value);
      }}
      placeholder="ユーザーを検索..."
    />
  );
}
```

**パターン:** `"use client"` はコンポーネントツリーの末端（葉）に押し込む。データはServer Componentからpropsとして渡す。

---

## 3. TypeScript 規約

```tsx
// types/user.ts
export interface User {
  id: string;
  name: string;
  email: string;
  role: "admin" | "member" | "viewer";
  createdAt: Date;
}

// コンポーネントのprops — 必ず明示的なinterfaceで定義
interface UserCardProps {
  user: User;
  onDelete?: (id: string) => void;
  className?: string;
}

// 非同期ページのprops（Next.js App Router）
interface PageProps {
  params: { id: string };
  searchParams: { [key: string]: string | string[] | undefined };
}
```

**ルール:**
- オブジェクト型には `type` より `interface` を優先。ユニオン・交差型には `type` を使う
- `any` は絶対に使わない。型が不明な場合は `unknown` + 型ガードで絞り込む
- 複数のファイルで使うprop型はエクスポートする
- ネイティブ要素を拡張する場合は `React.ComponentProps<"div">` を使う

---

## 4. コンポーネントパターン

### 標準コンポーネントテンプレート

```tsx
// components/users/user-card.tsx
import { cn } from "@/lib/utils";
import type { User } from "@/types/user";

interface UserCardProps {
  user: User;
  className?: string;
}

export function UserCard({ user, className }: UserCardProps) {
  return (
    <div className={cn("rounded-lg border bg-card p-4", className)}>
      <p className="font-medium">{user.name}</p>
      <p className="text-sm text-muted-foreground">{user.email}</p>
    </div>
  );
}
```

### ローディング / Suspenseスケルトン

```tsx
// components/users/user-card-skeleton.tsx
import { Skeleton } from "@/components/ui/skeleton";

export function UserCardSkeleton() {
  return (
    <div className="rounded-lg border bg-card p-4 space-y-2">
      <Skeleton className="h-4 w-32" />
      <Skeleton className="h-3 w-48" />
    </div>
  );
}
```

ページでの使用例:
```tsx
import { Suspense } from "react";

<Suspense fallback={<UserCardSkeleton />}>
  <UserCard user={user} />
</Suspense>
```

---

## 5. フォーム（Server Actions + Zod）

フォームのミューテーションにはAPIルートより **Server Actions** を優先する。

```tsx
// lib/validations/user.ts
import { z } from "zod";

export const createUserSchema = z.object({
  name: z.string().min(2, "名前は2文字以上で入力してください"),
  email: z.string().email("メールアドレスの形式が正しくありません"),
  role: z.enum(["admin", "member", "viewer"]),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
```

```tsx
// server/actions/users.ts
"use server";

import { revalidatePath } from "next/cache";
import { createUserSchema } from "@/lib/validations/user";

export async function createUser(formData: FormData) {
  const raw = Object.fromEntries(formData);
  const parsed = createUserSchema.safeParse(raw);

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  // await db.user.create({ data: parsed.data });
  revalidatePath("/users");
  return { success: true };
}
```

```tsx
// components/forms/create-user-form.tsx
"use client";

import { useActionState } from "react";
import { createUser } from "@/server/actions/users";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

const initialState = { error: undefined as any, success: false };

export function CreateUserForm() {
  const [state, formAction, isPending] = useActionState(createUser, initialState);

  return (
    <form action={formAction} className="space-y-4">
      <div className="space-y-1">
        <Label htmlFor="name">名前</Label>
        <Input id="name" name="name" required />
        {state.error?.name && (
          <p className="text-sm text-destructive">{state.error.name[0]}</p>
        )}
      </div>

      <div className="space-y-1">
        <Label htmlFor="email">メールアドレス</Label>
        <Input id="email" name="email" type="email" required />
        {state.error?.email && (
          <p className="text-sm text-destructive">{state.error.email[0]}</p>
        )}
      </div>

      <Button type="submit" disabled={isPending}>
        {isPending ? "作成中..." : "ユーザーを作成"}
      </Button>
    </form>
  );
}
```

---

## 6. データテーブル

詳細なパターン（TanStack Table + shadcn/ui DataTable）は `references/data-table.md` を参照。

概要:
- サーバーサイド: Server Componentでフェッチしてpropsとして渡す
- クライアントサイド: TanStack Tableでソート・フィルター・ページネーション
- カラム定義は `ColumnDef<TData>` を使う
- shadcn/uiの `DataTable` ラッパーコンポーネントを使う

---

## 7. モーダル・ダイアログ

shadcn/uiの `Dialog` コンポーネントを使う。モーダルの状態は親コンポーネントで管理し、単純なダイアログにグローバルStateは使わない。

```tsx
// components/users/delete-user-dialog.tsx
"use client";

import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { deleteUser } from "@/server/actions/users";
import { useState } from "react";

interface DeleteUserDialogProps {
  userId: string;
  userName: string;
}

export function DeleteUserDialog({ userId, userName }: DeleteUserDialogProps) {
  const [open, setOpen] = useState(false);
  const [isPending, setIsPending] = useState(false);

  async function handleDelete() {
    setIsPending(true);
    await deleteUser(userId);
    setOpen(false);
    setIsPending(false);
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button variant="destructive" size="sm">削除</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{userName} を削除しますか？</DialogTitle>
          <DialogDescription>
            この操作は取り消せません。
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => setOpen(false)}>キャンセル</Button>
          <Button variant="destructive" onClick={handleDelete} disabled={isPending}>
            {isPending ? "削除中..." : "削除する"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

---

## 8. Tailwind CSS 規約

```tsx
// 条件付きクラスには cn() を使う
import { cn } from "@/lib/utils"; // clsx + tailwind-merge

<div className={cn(
  "ベースクラス",
  isActive && "アクティブクラス",
  className  // UIコンポーネントには必ずclassNameを受け取る
)} />
```

**ルール:**
- shadcn/uiのデザイントークンを使う: `bg-background`、`text-foreground`、`text-muted-foreground`、`border`、`ring` など
- カラーをハードコードしない（`text-gray-500` は使わない）。セマンティックトークンを使う
- ページレベルの最大幅には `container` クラスを使う
- スペーシングは個別マージンより `space-y-*` / `gap-*` を優先
- レスポンシブ: モバイルファースト（`sm:`、`md:`、`lg:`）

---

## 9. APIルート（Route Handlers）

外部向けAPI（Webhook、公開APIなど）に使う。内部のミューテーションにはServer Actionsを優先する。

```tsx
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";

const paramsSchema = z.object({ id: z.string().cuid() });

export async function GET(
  _req: NextRequest,
  { params }: { params: { id: string } }
) {
  const parsed = paramsSchema.safeParse(params);
  if (!parsed.success) {
    return NextResponse.json({ error: "IDが不正です" }, { status: 400 });
  }

  // const user = await db.user.findUnique({ where: { id: parsed.data.id } });
  // if (!user) return NextResponse.json({ error: "見つかりません" }, { status: 404 });

  return NextResponse.json({ user: {} });
}
```

---

## 10. メタデータ・SEO

```tsx
// app/(dashboard)/users/page.tsx
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "ユーザー一覧 | MyApp",
  description: "チームメンバーを管理する",
};
```

動的メタデータ:
```tsx
export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const user = await getUser(params.id);
  return { title: `${user.name} | MyApp` };
}
```

---

## コード生成時のチェックリスト

1. Server / Client Componentをコメントで明示する
2. ページ以外のコンポーネントは名前付きエクスポート（defaultエクスポートはページのみ）
3. すべてのpropsにTypeScriptの型を付ける
4. UIコンポーネントには拡張用に `className?: string` propを追加する
5. コードブロックの先頭にファイルパスをコメントで示す
6. フォームには必ずZodバリデーション + Server Actionsを使う
7. リスト表示には必ずローディングスケルトンと空状態（EmptyState）を用意する

データテーブルの詳細は `references/data-table.md` を参照。
トースト、楽観的UI、無限スクロール等の追加パターンは `references/patterns.md` を参照。
