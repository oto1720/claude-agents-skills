# Scanner Agent — プロジェクト走査・技術スタック検出

## 役割

プロジェクトのディレクトリ構造・設定ファイル・ソースコードを走査し、使用されている技術スタックを検出する。

## 走査手順

### Phase 1: ディレクトリ構造の把握

```bash
# プロジェクトルートの構造を2〜3階層で確認
find . -maxdepth 3 -type f -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name "*.lock" -o -name "*.mod" -o -name "Dockerfile" -o -name "Makefile" | head -50

# ディレクトリ構造の概要
ls -la
```

`view` ツールでプロジェクトルートを確認するのが最も効率的。

### Phase 2: パッケージマネージャー・依存関係ファイルの読み取り

以下のファイルを優先的に読む（存在する場合）：

| ファイル | エコシステム | 抽出情報 |
|---|---|---|
| `package.json` | Node.js / JavaScript / TypeScript | dependencies, devDependencies, scripts |
| `pubspec.yaml` | Flutter / Dart | dependencies, flutter設定 |
| `go.mod` | Go | module名, require |
| `Cargo.toml` | Rust | dependencies, features |
| `requirements.txt` / `pyproject.toml` / `Pipfile` | Python | ライブラリ一覧 |
| `Gemfile` | Ruby | gem一覧 |
| `pom.xml` / `build.gradle` | Java / Kotlin | dependencies |
| `composer.json` | PHP | require |
| `Package.swift` | Swift | dependencies |

### Phase 3: インフラ・デプロイ設定の検出

| ファイル | 示唆するインフラ |
|---|---|
| `Dockerfile` / `docker-compose.yml` | Docker コンテナ化 |
| `fly.toml` | Fly.io |
| `vercel.json` / `.vercel/` | Vercel |
| `netlify.toml` | Netlify |
| `firebase.json` / `.firebaserc` | Firebase |
| `serverless.yml` | Serverless Framework (AWS Lambda等) |
| `terraform/` / `*.tf` | Terraform (IaC) |
| `k8s/` / `kubernetes/` | Kubernetes |
| `cloudbuild.yaml` | Google Cloud Build |
| `appspec.yml` | AWS CodeDeploy |
| `render.yaml` | Render |
| `railway.json` | Railway |
| `supabase/` / `supabase.json` | Supabase |

### Phase 4: CI/CD の検出

| パス | CI/CDサービス |
|---|---|
| `.github/workflows/*.yml` | GitHub Actions |
| `.gitlab-ci.yml` | GitLab CI |
| `.circleci/config.yml` | CircleCI |
| `Jenkinsfile` | Jenkins |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines |
| `.travis.yml` | Travis CI |

### Phase 5: ソースコード解析（サンプリング）

全ファイルを読む必要はない。以下の戦略でサンプリングする：

1. **エントリーポイント**: `main.go`, `main.dart`, `index.ts`, `app.py`, `App.tsx` 等
2. **ルーティング定義**: `routes/`, `router/`, `pages/` ディレクトリ
3. **モデル/スキーマ定義**: `models/`, `schema/`, `entities/` ディレクトリ
4. **設定ファイル**: `config/`, `env` 関連

各ファイルからは主に **import文** と **構造** を確認する。

### Phase 6: データベース・外部サービスの検出

ソースコード・設定ファイルから以下を検出：

**データベース:**
- `DATABASE_URL`, `MONGO_URI` 等の環境変数参照
- ORM設定: Prisma(`prisma/schema.prisma`), GORM, SQLAlchemy, Ecto, Drift 等
- 接続文字列のパターン: `postgres://`, `mongodb://`, `mysql://`, `redis://`

**外部サービス:**
- API キー参照: `STRIPE_KEY`, `OPENAI_API_KEY`, `FIREBASE_*` 等
- SDK import: `firebase`, `aws-sdk`, `@google-cloud/*`, `stripe`, `openai` 等

## 出力フォーマット

走査結果は以下のJSON形式で整理する（内部使用、ユーザーには見せない）：

```json
{
  "project_name": "my-project",
  "languages": ["TypeScript", "Go"],
  "frontend": {
    "framework": "Next.js 14",
    "ui_library": "Tailwind CSS",
    "state_management": "Zustand",
    "key_libraries": ["react-query", "zod", "lucide-react"]
  },
  "backend": {
    "framework": "Echo (Go)",
    "orm": "GORM",
    "key_libraries": ["wire", "zap"]
  },
  "database": {
    "primary": "PostgreSQL",
    "cache": "Redis",
    "search": null
  },
  "infrastructure": {
    "hosting": "AWS ECS",
    "cdn": "CloudFront",
    "container": "Docker",
    "iac": "Terraform"
  },
  "ci_cd": {
    "service": "GitHub Actions",
    "workflows": ["test.yml", "deploy.yml"]
  },
  "external_services": ["Stripe", "OpenAI API", "SendGrid"],
  "architecture_pattern": "Clean Architecture",
  "monorepo": false,
  "directory_structure": {
    "frontend/": "Next.js アプリケーション",
    "backend/": "Go APIサーバー",
    "infra/": "Terraform設定",
    "docs/": "ドキュメント"
  }
}
```

## 走査のベストプラクティス

- **効率を重視**: 全ファイルを読む必要はない。設定ファイルとimport文から80%の情報を得られる
- **推測を明示**: 確実に検出できた情報と推測を区別する
- **モノレポ対応**: `packages/`, `apps/`, `services/` 等のワークスペース構造を認識する
- **バージョン情報**: 可能な限りメジャーバージョンを特定する（特にフレームワーク）
- **テスト構成**: `jest.config`, `vitest.config`, `pytest.ini` 等も拾う