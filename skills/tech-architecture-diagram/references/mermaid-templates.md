# Mermaid テンプレート集

プロジェクトタイプ別のMermaidテンプレート。Renderer Agentがプロジェクトに合わせてカスタマイズして使用する。

---

## 1. フルスタック Web アプリ（Next.js + Go + PostgreSQL）

```mermaid
graph TD
    subgraph Client["🌐 Client"]
        BROWSER["Browser"]
    end

    subgraph Frontend["🖥️ Frontend — Next.js 14"]
        direction TB
        PAGES["App Router<br/>Pages & Layouts"]
        COMP["React Components<br/>shadcn/ui"]
        STATE["Zustand<br/>State Management"]
        QUERY["TanStack Query<br/>Data Fetching"]
    end

    subgraph Backend["⚙️ Backend — Go / Echo"]
        direction TB
        HANDLER["Handlers<br/>REST Endpoints"]
        MW["Middleware<br/>Auth / CORS / Log"]
        UC["UseCases<br/>Business Logic"]
        REPO["Repositories<br/>Data Access"]
    end

    subgraph Data["🗄️ Data Layer"]
        DB[("PostgreSQL")]
        CACHE[("Redis")]
    end

    subgraph External["☁️ External"]
        STRIPE["Stripe"]
        S3["AWS S3"]
    end

    BROWSER -->|"HTTPS"| PAGES
    PAGES --> COMP
    COMP --> STATE
    COMP --> QUERY
    QUERY -->|"REST API"| HANDLER
    HANDLER --> MW
    MW --> UC
    UC --> REPO
    REPO -->|"SQL"| DB
    REPO -->|"Cache"| CACHE
    UC -->|"Payment"| STRIPE
    UC -->|"Storage"| S3

    classDef frontend fill:#0ea5e9,stroke:#0284c7,color:#fff
    classDef backend fill:#10b981,stroke:#059669,color:#fff
    classDef data fill:#f59e0b,stroke:#d97706,color:#fff
    classDef external fill:#6b7280,stroke:#4b5563,color:#fff
    classDef client fill:#8b5cf6,stroke:#7c3aed,color:#fff

    class BROWSER client
    class PAGES,COMP,STATE,QUERY frontend
    class HANDLER,MW,UC,REPO backend
    class DB,CACHE data
    class STRIPE,S3 external
```

---

## 2. Flutter + Firebase モバイルアプリ

```mermaid
graph TD
    subgraph App["📱 Flutter App"]
        direction TB
        UI["Screens & Widgets<br/>Material Design"]
        PROVIDER["Riverpod<br/>State Management"]
        USECASE["UseCases"]
        REPO_IF["Repository<br/>Interfaces"]
    end

    subgraph Data["📦 Data Layer"]
        direction TB
        REPO_IMPL["Repository<br/>Implementations"]
        LOCAL["SharedPreferences<br/>/ Hive"]
        DTO["DTOs &<br/>Serialization"]
    end

    subgraph Firebase["🔥 Firebase"]
        direction TB
        AUTH["Firebase Auth"]
        FS["Cloud Firestore"]
        STORAGE["Cloud Storage"]
        FCM["Cloud Messaging"]
        FUNC["Cloud Functions"]
    end

    UI --> PROVIDER
    PROVIDER --> USECASE
    USECASE --> REPO_IF
    REPO_IF -.->|"implements"| REPO_IMPL
    REPO_IMPL --> LOCAL
    REPO_IMPL --> DTO
    REPO_IMPL -->|"REST/gRPC"| AUTH
    REPO_IMPL -->|"Realtime"| FS
    REPO_IMPL -->|"Upload"| STORAGE
    REPO_IMPL -->|"Push"| FCM
    FS -->|"Trigger"| FUNC

    classDef app fill:#02569B,stroke:#01478B,color:#fff
    classDef data fill:#0d9488,stroke:#0f766e,color:#fff
    classDef firebase fill:#FF9100,stroke:#E65100,color:#fff

    class UI,PROVIDER,USECASE,REPO_IF app
    class REPO_IMPL,LOCAL,DTO data
    class AUTH,FS,STORAGE,FCM,FUNC firebase
```

---

## 3. マイクロサービス構成

```mermaid
graph TD
    subgraph Client["🌐 Clients"]
        WEB["Web App"]
        MOBILE["Mobile App"]
    end

    subgraph Gateway["🚪 API Gateway"]
        GW["Kong / Nginx<br/>Load Balancer"]
    end

    subgraph Services["⚙️ Services"]
        direction TB
        USER["User Service<br/>Go / PostgreSQL"]
        ORDER["Order Service<br/>Go / PostgreSQL"]
        PAYMENT["Payment Service<br/>Node.js / Stripe"]
        NOTIFY["Notification Service<br/>Python / SendGrid"]
    end

    subgraph Messaging["📨 Message Bus"]
        KAFKA["Apache Kafka"]
    end

    subgraph Data["🗄️ Data Stores"]
        DB_USER[("Users DB")]
        DB_ORDER[("Orders DB")]
        REDIS[("Redis Cache")]
    end

    subgraph Infra["🏗️ Infrastructure"]
        K8S["Kubernetes"]
        PROM["Prometheus"]
        GRAF["Grafana"]
    end

    WEB -->|"HTTPS"| GW
    MOBILE -->|"HTTPS"| GW
    GW --> USER
    GW --> ORDER
    GW --> PAYMENT
    USER --> DB_USER
    ORDER --> DB_ORDER
    ORDER --> REDIS
    ORDER -->|"event"| KAFKA
    KAFKA -->|"subscribe"| PAYMENT
    KAFKA -->|"subscribe"| NOTIFY
    USER --> K8S
    PROM --> GRAF

    classDef client fill:#8b5cf6,stroke:#7c3aed,color:#fff
    classDef gateway fill:#ec4899,stroke:#db2777,color:#fff
    classDef service fill:#10b981,stroke:#059669,color:#fff
    classDef messaging fill:#f97316,stroke:#ea580c,color:#fff
    classDef data fill:#f59e0b,stroke:#d97706,color:#fff
    classDef infra fill:#6366f1,stroke:#4f46e5,color:#fff

    class WEB,MOBILE client
    class GW gateway
    class USER,ORDER,PAYMENT,NOTIFY service
    class KAFKA messaging
    class DB_USER,DB_ORDER,REDIS data
    class K8S,PROM,GRAF infra
```

---

## 4. 静的サイト / JAMstack

```mermaid
graph LR
    subgraph Dev["🛠️ Development"]
        MD["Markdown / MDX"]
        NEXT["Next.js / Astro"]
        CMS["Headless CMS<br/>Contentful / Notion"]
    end

    subgraph Build["🔨 Build"]
        GHA["GitHub Actions"]
        SSG["Static Generation"]
    end

    subgraph Deploy["🚀 Deploy"]
        VERCEL["Vercel / Netlify"]
        CDN["Edge CDN"]
    end

    subgraph Runtime["⚡ Runtime APIs"]
        FUNC["Serverless Functions"]
        DB[("Supabase / PlanetScale")]
    end

    MD --> NEXT
    CMS -->|"API"| NEXT
    NEXT --> GHA
    GHA --> SSG
    SSG --> VERCEL
    VERCEL --> CDN
    CDN -->|"Dynamic"| FUNC
    FUNC --> DB

    classDef dev fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef build fill:#f59e0b,stroke:#d97706,color:#fff
    classDef deploy fill:#10b981,stroke:#059669,color:#fff
    classDef runtime fill:#8b5cf6,stroke:#7c3aed,color:#fff

    class MD,NEXT,CMS dev
    class GHA,SSG build
    class VERCEL,CDN deploy
    class FUNC,DB runtime
```

---

## 5. Clean Architecture レイヤー図

```mermaid
graph TB
    subgraph Presentation["📱 Presentation Layer"]
        direction LR
        SCREEN["Screens"]
        WIDGET["Widgets"]
        VM["ViewModel /<br/>Controller"]
    end

    subgraph Application["⚡ Application Layer"]
        direction LR
        UC["UseCases"]
        DTO_APP["DTOs"]
    end

    subgraph Domain["💎 Domain Layer"]
        direction LR
        ENTITY["Entities"]
        VO["Value Objects"]
        REPO_IF["Repository<br/>Interfaces"]
        DS["Domain Services"]
    end

    subgraph Infrastructure["🔧 Infrastructure Layer"]
        direction LR
        REPO_IMPL["Repository<br/>Impl"]
        API["API Client"]
        DB_IMPL["DB Access"]
        CACHE_IMPL["Cache"]
    end

    Presentation -->|"calls"| Application
    Application -->|"uses"| Domain
    Infrastructure -.->|"implements"| Domain

    classDef pres fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef app fill:#8b5cf6,stroke:#7c3aed,color:#fff
    classDef domain fill:#f59e0b,stroke:#d97706,color:#fff
    classDef infra fill:#10b981,stroke:#059669,color:#fff

    class SCREEN,WIDGET,VM pres
    class UC,DTO_APP app
    class ENTITY,VO,REPO_IF,DS domain
    class REPO_IMPL,API,DB_IMPL,CACHE_IMPL infra
```

---

## 6. CI/CD パイプライン図

```mermaid
graph LR
    subgraph Trigger["🔔 Trigger"]
        PUSH["Git Push"]
        PR["Pull Request"]
    end

    subgraph CI["🔍 CI Pipeline"]
        direction TB
        LINT["Lint & Format"]
        TEST["Unit Tests"]
        BUILD["Build"]
        E2E["E2E Tests"]
    end

    subgraph CD["🚀 CD Pipeline"]
        direction TB
        STAGE["Deploy to<br/>Staging"]
        REVIEW["Manual<br/>Review"]
        PROD["Deploy to<br/>Production"]
    end

    subgraph Monitor["📊 Monitoring"]
        HEALTH["Health Check"]
        ALERT["Alerts"]
    end

    PUSH --> LINT
    PR --> LINT
    LINT --> TEST
    TEST --> BUILD
    BUILD --> E2E
    E2E --> STAGE
    STAGE --> REVIEW
    REVIEW -->|"approve"| PROD
    PROD --> HEALTH
    HEALTH --> ALERT

    classDef trigger fill:#6b7280,stroke:#4b5563,color:#fff
    classDef ci fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef cd fill:#10b981,stroke:#059669,color:#fff
    classDef monitor fill:#f59e0b,stroke:#d97706,color:#fff

    class PUSH,PR trigger
    class LINT,TEST,BUILD,E2E ci
    class STAGE,REVIEW,PROD cd
    class HEALTH,ALERT monitor
```

---

## カスタマイズのポイント

1. テンプレートはそのまま使わず、プロジェクトの実態に合わせて修正する
2. 存在しない技術/サービスのノードは削除する
3. プロジェクト固有の特徴（独自のミドルウェア、カスタムツール等）を追加する
4. ノード内のテキストはプロジェクトで実際に使われている技術名・バージョンに置き換える
5. 接続線のラベルはプロジェクトの実際の通信方式に合わせる