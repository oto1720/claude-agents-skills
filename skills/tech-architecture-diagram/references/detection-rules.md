# 技術スタック検出ルール

## 目次

1. [言語検出](#言語検出)
2. [フレームワーク検出](#フレームワーク検出)
3. [データベース検出](#データベース検出)
4. [インフラ・クラウド検出](#インフラクラウド検出)
5. [状態管理・UIライブラリ検出](#状態管理uiライブラリ検出)
6. [テストフレームワーク検出](#テストフレームワーク検出)

---

## 言語検出

| シグナル | 言語 |
|---|---|
| `tsconfig.json`, `.ts`/`.tsx` ファイル | TypeScript |
| `.js`/`.jsx` ファイル（tsconfig無し） | JavaScript |
| `go.mod`, `.go` ファイル | Go |
| `pubspec.yaml`, `.dart` ファイル | Dart (Flutter) |
| `Cargo.toml`, `.rs` ファイル | Rust |
| `requirements.txt`/`pyproject.toml`, `.py` ファイル | Python |
| `Gemfile`, `.rb` ファイル | Ruby |
| `pom.xml`/`build.gradle`, `.java` ファイル | Java |
| `build.gradle.kts`, `.kt` ファイル | Kotlin |
| `Package.swift`, `.swift` ファイル | Swift |
| `*.php`, `composer.json` | PHP |
| `mix.exs`, `.ex`/`.exs` ファイル | Elixir |

## フレームワーク検出

### JavaScript / TypeScript

| シグナル | フレームワーク |
|---|---|
| `next.config.*`, `app/` or `pages/` + `package.json` に `next` | Next.js |
| `nuxt.config.*`, `package.json` に `nuxt` | Nuxt.js |
| `package.json` に `react` (Next.js無し) | React (SPA) |
| `angular.json`, `package.json` に `@angular/core` | Angular |
| `package.json` に `vue` (Nuxt無し) | Vue.js (SPA) |
| `svelte.config.*`, `package.json` に `svelte` | SvelteKit / Svelte |
| `astro.config.*` | Astro |
| `remix.config.*`, `package.json` に `@remix-run` | Remix |
| `package.json` に `express` | Express.js |
| `package.json` に `fastify` | Fastify |
| `package.json` に `hono` | Hono |
| `package.json` に `@nestjs/core` | NestJS |

### Go

| シグナル | フレームワーク |
|---|---|
| `go.mod` に `github.com/labstack/echo` | Echo |
| `go.mod` に `github.com/gin-gonic/gin` | Gin |
| `go.mod` に `github.com/gofiber/fiber` | Fiber |
| `go.mod` に `github.com/go-chi/chi` | Chi |
| `go.mod` に `google.golang.org/grpc` | gRPC |

### Flutter / Dart

| シグナル | フレームワーク/パターン |
|---|---|
| `pubspec.yaml` に `flutter` | Flutter |
| `pubspec.yaml` に `flutter_riverpod` or `riverpod` | Riverpod状態管理 |
| `pubspec.yaml` に `flutter_bloc` | BLoC状態管理 |
| `pubspec.yaml` に `provider` | Provider状態管理 |
| `pubspec.yaml` に `get` | GetX |

### Python

| シグナル | フレームワーク |
|---|---|
| `manage.py`, `settings.py` | Django |
| imports に `flask` | Flask |
| imports に `fastapi` | FastAPI |
| imports に `streamlit` | Streamlit |

### Ruby

| シグナル | フレームワーク |
|---|---|
| `Gemfile` に `rails`, `config/routes.rb` | Ruby on Rails |
| `Gemfile` に `sinatra` | Sinatra |

## データベース検出

| シグナル | データベース |
|---|---|
| `prisma/schema.prisma` | Prisma ORM (+ DB種類はschema内で判定) |
| `prisma/schema.prisma` に `provider = "postgresql"` | PostgreSQL |
| `prisma/schema.prisma` に `provider = "mysql"` | MySQL |
| `prisma/schema.prisma` に `provider = "sqlite"` | SQLite |
| `drizzle.config.*` | Drizzle ORM |
| 環境変数 `DATABASE_URL` に `postgres` | PostgreSQL |
| 環境変数 `MONGO_URI` / `MONGODB_URI` | MongoDB |
| `go.mod` に `gorm.io/gorm` | GORM |
| `go.mod` に `github.com/jmoiron/sqlx` | sqlx (Go) |
| `pubspec.yaml` に `cloud_firestore` | Firestore |
| `pubspec.yaml` に `sqflite` | SQLite (Flutter) |
| `pubspec.yaml` に `drift` | Drift ORM (Flutter) |
| `pubspec.yaml` に `hive` | Hive (Flutter local DB) |
| `redis` in dependencies | Redis |
| `package.json` に `ioredis` or `redis` | Redis (Node.js) |
| `go.mod` に `github.com/go-redis/redis` | Redis (Go) |
| `supabase/` ディレクトリ, `@supabase/supabase-js` | Supabase (PostgreSQL) |

## インフラ・クラウド検出

| シグナル | インフラ |
|---|---|
| `firebase.json`, `.firebaserc` | Firebase Hosting |
| `pubspec.yaml` に `firebase_*` | Firebase (Flutter) |
| `package.json` に `firebase-admin` | Firebase Admin SDK |
| `vercel.json`, `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `fly.toml` | Fly.io |
| `render.yaml` | Render |
| `Dockerfile` | Docker |
| `docker-compose.yml` | Docker Compose |
| `*.tf` ファイル | Terraform |
| `serverless.yml` | Serverless Framework |
| `package.json` に `aws-sdk` or `@aws-sdk/*` | AWS SDK |
| `package.json` に `@google-cloud/*` | Google Cloud |
| `package.json` に `@azure/*` | Azure |
| `cloudflare.toml` / `wrangler.toml` | Cloudflare Workers |

## 状態管理・UIライブラリ検出

### React エコシステム

| シグナル | ライブラリ |
|---|---|
| `package.json` に `zustand` | Zustand |
| `package.json` に `@reduxjs/toolkit` or `redux` | Redux |
| `package.json` に `recoil` | Recoil |
| `package.json` に `jotai` | Jotai |
| `package.json` に `@tanstack/react-query` | TanStack Query |
| `package.json` に `tailwindcss` | Tailwind CSS |
| `package.json` に `@shadcn/ui` or `components/ui/` | shadcn/ui |
| `package.json` に `@chakra-ui/react` | Chakra UI |
| `package.json` に `@mui/material` | Material UI |

### Flutter エコシステム

| シグナル | ライブラリ |
|---|---|
| `pubspec.yaml` に `flutter_hooks` | Flutter Hooks |
| `pubspec.yaml` に `freezed` | Freezed (immutable models) |
| `pubspec.yaml` に `json_serializable` | JSON Serializable |
| `pubspec.yaml` に `auto_route` | Auto Route |
| `pubspec.yaml` に `go_router` | GoRouter |
| `pubspec.yaml` に `dio` | Dio HTTP Client |

## テストフレームワーク検出

| シグナル | テストFW |
|---|---|
| `jest.config.*`, `package.json` に `jest` | Jest |
| `vitest.config.*`, `package.json` に `vitest` | Vitest |
| `cypress.config.*` | Cypress (E2E) |
| `playwright.config.*` | Playwright (E2E) |
| `*_test.go` ファイル | Go testing |
| `*_test.dart` ファイル | Flutter/Dart testing |
| `pytest.ini` / `conftest.py` | pytest |
| `spec/` + Gemfile に `rspec` | RSpec |