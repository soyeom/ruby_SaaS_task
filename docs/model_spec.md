# モデル設計書

本ドキュメントでは、本アプリケーションで使用する主要モデルのテーブル構造およびリレーションを定義する。

---

## 1. users テーブル

| カラム名 | 型 | 制約 | 説明 |
|--------|----|------|------|
| id | bigint | PK | ユーザーID |
| login_id | string | NOT NULL, UNIQUE | ログイン用ID |
| password_digest | string | | パスワードハッシュ |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### リレーション
- `has_many :members`
- `has_many :workspaces, through: :members`
- `has_many :tasks`, foreign_key: `assignee_id`
- `has_many :task_progresses`

---

## 2. workspaces テーブル

| カラム名 | 型 | 制約 | 説明 |
|--------|----|------|------|
| id | bigint | PK | ワークスペースID |
| name | string | NOT NULL | ワークスペース名 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### リレーション
- `has_many :members`
- `has_many :users, through: :members`
- `has_many :tasks`
- `has_many :task_progresses`

---

## 3. members テーブル

| カラム名 | 型 | 制約 | 説明 |
|--------|----|------|------|
| id | bigint | PK | メンバーID |
| user_id | bigint | NOT NULL, FK | ユーザーID |
| workspace_id | bigint | NOT NULL, FK | ワークスペースID |
| role | integer | NOT NULL, default: 0 | 権限（0: member, 1: owner） |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### 制約
- `(user_id, workspace_id)` の組み合わせは一意

### リレーション
- `belongs_to :user`
- `belongs_to :workspace`

---

## 4. tasks テーブル

| カラム名 | 型 | 制約 | 説明 |
|--------|----|------|------|
| id | bigint | PK | タスクID |
| workspace_id | bigint | NOT NULL, FK | 所属ワークスペース |
| assignee_id | bigint | FK | 担当ユーザーID |
| title | string | NOT NULL | タスクタイトル |
| description | text | | 詳細説明 |
| status | integer | NOT NULL, default: 0 | 状態（0: todo / 1: doing / 2: done） |
| category | string | | カテゴリ名 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### リレーション
- `belongs_to :workspace`
- `belongs_to :assignee`, class_name: "User", optional: true

---

## 5. task_progresses テーブル

| カラム名 | 型 | 制約 | 説明 |
|--------|----|------|------|
| id | bigint | PK | 進捗ID |
| workspace_id | bigint | NOT NULL, FK | 対象ワークスペース |
| user_id | bigint | NOT NULL, FK | 対象ユーザー |
| total_tasks | integer | NOT NULL, default: 0 | 総タスク数 |
| completed_tasks | integer | NOT NULL, default: 0 | 完了タスク数 |
| completion_rate | integer | NOT NULL, default: 0 | 完了率（%） |
| aggregated_at | datetime | NOT NULL | 集計日時 |
| created_at | datetime | NOT NULL | 作成日時 |
| updated_at | datetime | NOT NULL | 更新日時 |

### 制約
- `(workspace_id, user_id)` の組み合わせは一意

### リレーション
- `belongs_to :workspace`
- `belongs_to :user`

---

## 6. ERリレーション概要

```
User 1 --- n Member n --- 1 Workspace
User 1 --- n Task
Workspace 1 --- n Task
User 1 --- n TaskProgress
Workspace 1 --- n TaskProgress
```