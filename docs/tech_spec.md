# 技術仕様書（tech_spec.md）

本プロジェクトで使用した技術スタックおよび開発環境を以下に示す。

---

## 1. 使用技術

| 分類 | 技術 |
|------|------|
| バックエンド | Ruby on Rails（APIモード） |
| フロントエンド | Vue.js 3 + Vite |
| データベース | PostgreSQL |
| 認証 | Rails セッション |
| バッチ処理 | Rake タスク + Rufus Scheduler |
| コンテナ | Docker / Docker Compose |
| バージョン管理 | Git + GitHub |

---

## 2. バージョン情報

| 技術 | バージョン |
|------|-----------|
| Ruby | 3.3.10 |
| Rails | 8.1.1 |
| Node.js | v20.19.0 |
| npm | 10.8.2 |
| PostgreSQL | 16.x |
| Docker | 27.2.0 |
| Docker Compose | v2 系 |

---
## 3. Docker 利用

本プロジェクトでは、**データベース環境構築のために PostgreSQL を Docker コンテナとして使用**しています。  
バックエンドおよびフロントエンドはローカル環境で実行し、DB のみコンテナ化しています。

以下は使用している `docker-compose.yml` の内容です（参考用）：

```yaml
version: "3.8"

services:
  db:
    image: postgres:16
    platform: linux/amd64
    container_name: ruby_saas_postgres
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: always

volumes:
  postgres-data:
```

---