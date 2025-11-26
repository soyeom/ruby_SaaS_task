# Ruby SaaS タスク管理システム

| ワークスペース単位でタスクを管理できる SaaS 型タスク管理アプリケーションです !

---

## ✨ 主な機能

- ユーザー認証（ログイン / サインアップ / ログアウト）
- ワークスペース管理
- メンバー管理（オーナー / メンバー）
- タスク管理（作成・更新・削除）
- タスクフィルタリング（ステータス・カテゴリ・担当者）
- 担当者別タスク進捗の可視化
- Rake タスクによるタスク進捗の定期集計

---

## 🛠 使用技術

| 分類 | 技術 |
|------|------|
| バックエンド | Ruby on Rails 8.1.1（API モード） |
| フロントエンド | Vue.js 3 + Vite + Pug |
| データベース | PostgreSQL 16（Docker コンテナ） |
| 認証 | Rails セッション方式 |
| ジョブ管理 | Rake タスク + Rufus Scheduler |
| コンテナ | Docker |
| バージョン管理 | Git / GitHub |

---

## 🚀 開発環境

| 項目 | バージョン |
|------|-----------|
| Ruby | 3.3.10 |
| Rails | 8.1.1 |
| Node.js | 20.19.0 |
| npm | 10.8.2 |
| PostgreSQL | 16 |
| Docker | 27.2.0 |

---

## 🐳 Docker 利用
本プロジェクトでは、開発環境の統一のため  
PostgreSQL を Docker コンテナとして使用しています。

---

## 📁 ディレクトリ構成

/
├─ backend         : Rails API バックエンド  
├─ frontend        : Vue.js フロントエンド  
├─ docs            : 設計資料・仕様書  
└─ README.md  

---

## ⚙️ 実行方法

### バックエンド起動

<!-- 実行コマンド -->
`cd backend`  
`bundle install`  
`rails db:create db:migrate`  
`rails s`  

### フロントエンド起動

<!-- 実行コマンド -->
`cd frontend`  
`npm install`  
`npm run dev`  

---

## 🔁 バッチ処理

担当者別タスク進捗を定期集計します。

<!-- 一度だけ実行 -->
`bundle exec rake task_progress:aggregate`  

<!-- 定期実行（5分ごと） -->
`bundle exec rake task_progress:daemon`

---

## 🧪 テスト

Rails 側にて RSpec を使用しています。

<!-- テスト実行コマンド -->
`bundle exec rspec spec/models`
`bundle exec rspec spec/requests` 

---

## 📄 設計書

`/docs` ディレクトリに以下の資料があります。

- 画面仕様書  
- 機能設計書  
- モデル設計書  
- 技術仕様書（tech_spec.md）

---
