# Next.js UIの追加パターン集

## トースト通知（sonner）

```bash
npm install sonner
```

```tsx
// app/layout.tsx
import { Toaster } from "sonner";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ja">
      <body>
        {children}
        <Toaster richColors position="top-right" />
      </body>
    </html>
  );
}
```

```tsx
// Client Componentでの使用
"use client";
import { toast } from "sonner";

async function handleSubmit() {
  try {
    await someAction();
    toast.success("保存しました");
  } catch {
    toast.error("エラーが発生しました");
  }
}
```

---

## 楽観的UI（useOptimistic）

サーバーのレスポンスを待たずに即座にUIを更新したい場合に使う。

```tsx
"use client";

import { useOptimistic, useTransition } from "react";
import { toggleLike } from "@/server/actions/posts";

interface LikeButtonProps {
  postId: string;
  initialLikes: number;
  initialLiked: boolean;
}

export function LikeButton({ postId, initialLikes, initialLiked }: LikeButtonProps) {
  const [isPending, startTransition] = useTransition();
  const [optimistic, setOptimistic] = useOptimistic(
    { likes: initialLikes, liked: initialLiked },
    (state, _action: "toggle") => ({
      likes: state.liked ? state.likes - 1 : state.likes + 1,
      liked: !state.liked,
    })
  );

  function handleClick() {
    startTransition(async () => {
      setOptimistic("toggle");
      await toggleLike(postId);
    });
  }

  return (
    <button onClick={handleClick} disabled={isPending}>
      {optimistic.liked ? "♥" : "♡"} {optimistic.likes}
    </button>
  );
}
```

---

## 無限スクロール

```tsx
"use client";

import { useState, useEffect, useRef } from "react";
import { getPosts } from "@/server/queries/posts";
import type { Post } from "@/types/post";

interface InfinitePostListProps {
  initialPosts: Post[];
}

export function InfinitePostList({ initialPosts }: InfinitePostListProps) {
  const [posts, setPosts] = useState(initialPosts);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const loaderRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const observer = new IntersectionObserver(
      async (entries) => {
        if (entries[0].isIntersecting && hasMore && !isLoading) {
          setIsLoading(true);
          const nextPage = page + 1;
          const newPosts = await getPosts({ page: nextPage });
          if (newPosts.length === 0) {
            setHasMore(false);
          } else {
            setPosts((prev) => [...prev, ...newPosts]);
            setPage(nextPage);
          }
          setIsLoading(false);
        }
      },
      { threshold: 0.5 }
    );

    if (loaderRef.current) observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [page, hasMore, isLoading]);

  return (
    <div className="space-y-4">
      {posts.map((post) => (
        <div key={post.id}>{post.title}</div>
      ))}
      <div ref={loaderRef} className="py-4 text-center text-muted-foreground">
        {isLoading ? "読み込み中..." : hasMore ? "" : "すべて表示しました"}
      </div>
    </div>
  );
}
```

---

## URL状態管理（nuqs）

フィルター・ソート・ページネーションの状態をURLクエリパラメータと同期する。

```bash
npm install nuqs
```

```tsx
// app/(dashboard)/products/page.tsx
import { SearchParams } from "nuqs/server";
import { ProductList } from "@/components/products/product-list";
import { getProducts } from "@/server/queries/products";

interface PageProps {
  searchParams: SearchParams;
}

export default async function ProductsPage({ searchParams }: PageProps) {
  const { q = "", sort = "createdAt", page = "1" } = searchParams as Record<string, string>;

  const products = await getProducts({
    query: q,
    sort,
    page: Number(page),
  });

  return <ProductList products={products} />;
}
```

```tsx
// components/products/product-filters.tsx
"use client";

import { useQueryState } from "nuqs";
import { Input } from "@/components/ui/input";

export function ProductFilters() {
  const [query, setQuery] = useQueryState("q", { defaultValue: "" });

  return (
    <Input
      value={query}
      onChange={(e) => setQuery(e.target.value || null)}
      placeholder="商品を検索..."
    />
  );
}
```

---

## 空状態（EmptyState）コンポーネント

リスト表示には必ず空状態を用意する。

```tsx
// components/ui/empty-state.tsx
import type { LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export function EmptyState({ icon: Icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <div className="rounded-full bg-muted p-4 mb-4">
        <Icon className="h-8 w-8 text-muted-foreground" />
      </div>
      <h3 className="text-lg font-semibold mb-1">{title}</h3>
      {description && (
        <p className="text-sm text-muted-foreground mb-4 max-w-xs">{description}</p>
      )}
      {action && (
        <Button onClick={action.onClick}>{action.label}</Button>
      )}
    </div>
  );
}
```

使用例:
```tsx
import { Users } from "lucide-react";
import { EmptyState } from "@/components/ui/empty-state";

<EmptyState
  icon={Users}
  title="ユーザーがいません"
  description="まだユーザーが登録されていません。"
  action={{ label: "ユーザーを追加", onClick: () => setOpen(true) }}
/>
```

---

## エラーバウンダリ（error.tsx）

```tsx
// app/(dashboard)/users/error.tsx
"use client";

import { useEffect } from "react";
import { Button } from "@/components/ui/button";

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function Error({ error, reset }: ErrorProps) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex flex-col items-center justify-center py-16 text-center">
      <h2 className="text-xl font-semibold mb-2">エラーが発生しました</h2>
      <p className="text-sm text-muted-foreground mb-4">{error.message}</p>
      <Button onClick={reset}>再試行</Button>
    </div>
  );
}
```

---

## サイドバーレイアウトパターン

```tsx
// app/(dashboard)/layout.tsx
import { Sidebar } from "@/components/layouts/sidebar";
import { Header } from "@/components/layouts/header";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex flex-col flex-1 overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
```

---

## cn() ユーティリティ

必ずプロジェクトに含める:

```tsx
// lib/utils.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```bash
npm install clsx tailwind-merge
```
